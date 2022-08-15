// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/**
 * @title Furio AddLiquidity
 * @author Steve Harmeyer
 * @notice This contract offers LP holders can stake their holded LP token.
 */

/// @custom:security-contact security@furio.io
contract LPStaking is BaseContract, ERC20Upgradeable 
{
    using SafeMath for uint256;

    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() public initializer {
        __BaseContract_init();
        _lastUpdateTime = block.timestamp;
        _dividendsPerShareAccuracyFactor = 1e36;
    }
    /**
     * Staker struct.
     */
    struct Staker {
        uint256 stakingAmount;
        uint256 boostedAmount;
        uint256 rewardDebt;
        uint256 lastStakingUpdateTime;
        uint256 stakingPeriod;
    }
    /**
     * variables
     */
    address public lpAddress;
    uint256  _lastUpdateTime; //LP RewardPool Updated time
    uint256  _accLPPerShare;  //Accumulated LPs per share, times 1e36. See below.
    uint256  _dividendsPerShareAccuracyFactor; //1e36

    uint256 public totalStakerNum; //total staker number
    uint256 public totalStakingAmount; //total staker amount
    uint256  _totalBoostedAmount; //total boosted amount for reward distrubution
    uint256  _totalReward;  //total LP amount for LP reward to LP stakers
    uint256  _totalReflection; //total LP amount to LP reflection to LP holders
    uint256  _LPLockAmount; // total locked LP amount. except from LP reflection
    address  _LPLockReceiver; //address for LP lock
    address[] LPholders; // LP holders address. to get LP reflection, they have to register thier address here.

    /**
     * Mappings.
     */
    mapping(address => Staker) public stakers;
    mapping(address => uint256) _LPholderIndexes;

    /**
     * Event.
     */
    event Stake(address indexed staker, uint256 amount, uint256 duration);
    event ClaimRewards(address indexed staker, uint256 amount);
    event Compound(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 amount);

    /**
     * Update addresses.
     * @dev Updates stored addresses.
     */
    function updateAddresses() public {
        IUniswapV2Factory _factory_ = IUniswapV2Factory(
            addressBook.get("factory")
        );
        lpAddress = _factory_.getPair(
            addressBook.get("payment"),
            addressBook.get("token")
        );
        _LPLockReceiver = addressBook.get("lpLockReceiver");
    }

    /**
     * total LP amount holed this contract
     */
    function _LPSupply_() external view returns (uint256) {
        return IERC20(lpAddress).balanceOf(address(this));
    }

    /**
     * claimable Reward for LP stakers
     * @param stakerAddress_ staker address
     * @return pending_ claimable LP amount
     */
    function pendingReward(address stakerAddress_)
        public
        view
        returns (uint256 pending_)
    {
        if (stakers[stakerAddress_].stakingAmount <= 0) return 0;

        pending_ = stakers[stakerAddress_].boostedAmount
            .mul(_accLPPerShare)
            .div(_dividendsPerShareAccuracyFactor)
            .sub(stakers[stakerAddress_].rewardDebt);
    }

    /**
     * Update reward pool for LP stakers.
     * @dev update _accLPPerShare
     */
    function updateRewardPool() public {
        if (lpAddress == address(0)) updateAddresses();

        uint256 _deltaTime_ = block.timestamp - _lastUpdateTime;
        if (_deltaTime_ < 24 hours) return;
        uint256 _times_ = _deltaTime_.div(24 hours);
        if (_times_ > 40) _times_ = 40;

        uint256 _lpSupply_ = IERC20(lpAddress).balanceOf(address(this));
        if (_lpSupply_ == 0) {
            _lastUpdateTime = block.timestamp;
            return;
        }

        _totalReward = IERC20(lpAddress).balanceOf(address(this))
            .sub(_totalBoostedAmount)
            .sub(_totalReflection);
        uint256 _amountForReward_ = _totalReward.mul(25).div(1000).mul(_times_);
        uint256 _RewardPerShare_ = _amountForReward_
            .mul(_dividendsPerShareAccuracyFactor)
            .div(_totalBoostedAmount);
        _accLPPerShare = _accLPPerShare.add(_RewardPerShare_);

        _totalReward = _totalReward.sub(_amountForReward_);
        _lastUpdateTime = _lastUpdateTime.add(_times_.mul(24 hours));
    }

    /**
     * stake function
     * @param amount_ LP amount
     * @param durationIndex_ duration index.
     * @dev approve LP before staking.
     */
    function stake(uint256 amount_, uint256 durationIndex_) public {
        if (lpAddress == address(0) || _LPLockReceiver == address(0))
            updateAddresses();

        require(IERC20(lpAddress).balanceOf(msg.sender) >= amount_, "Insufficient balance!");
        require(durationIndex_ <= 3, "Non exist duration!");

        if (stakers[msg.sender].stakingAmount == 0) totalStakerNum++;

        updateRewardPool();

        if (stakers[msg.sender].stakingAmount > 0) {
            uint256 _pending_ = pendingReward(msg.sender);
            IERC20(lpAddress).transfer(msg.sender, _pending_);
        }

        IERC20(lpAddress).transferFrom(
            msg.sender,
            address(this),
            amount_.mul(970).div(1000)
        );

        IERC20(lpAddress).transferFrom(
            msg.sender,
            _LPLockReceiver,
            amount_.mul(30).div(1000)
        );

        uint256 _boostingAmount_ = amount_;
        if (durationIndex_ == 0) {
            _boostingAmount_ = amount_;
            stakers[msg.sender].stakingPeriod = 0;
        }

        if (durationIndex_ == 1) {
            _boostingAmount_ = amount_.mul(102).div(100);
            stakers[msg.sender].stakingPeriod = 30 days;
        }
        if (durationIndex_ == 2) {
            _boostingAmount_ = amount_.mul(105).div(100);
            stakers[msg.sender].stakingPeriod = 60 days;
        }
        if (durationIndex_ == 3) {
            _boostingAmount_ = amount_.mul(110).div(100);
            stakers[msg.sender].stakingPeriod = 90 days;
        }

        stakers[msg.sender].stakingAmount = stakers[msg.sender].stakingAmount
            .add(amount_.mul(900).div(1000));
        stakers[msg.sender].boostedAmount = stakers[msg.sender].boostedAmount
            .add(_boostingAmount_.mul(900).div(1000));
        stakers[msg.sender].rewardDebt = stakers[msg.sender].boostedAmount
            .mul(_accLPPerShare)
            .div(_dividendsPerShareAccuracyFactor);
        stakers[msg.sender].lastStakingUpdateTime == block.timestamp;

        totalStakingAmount = totalStakingAmount.add(amount_.mul(900).div(1000));
        _totalBoostedAmount = _totalBoostedAmount.add(
            _boostingAmount_.mul(900).div(1000)
        );
        _totalReflection = _totalReflection.add(amount_.mul(20).div(1000));
        _LPLockAmount = _LPLockAmount.add(amount_.mul(30).div(1000));

        _distributeReflectionRewards();

        emit Stake(
            msg.sender,
            amount_,
            stakers[msg.sender].stakingPeriod
        );
    }

    /**
     * claim reward function for LP stakers
     @notice stakers can claim every 24 hours.
     */
    function claimRewards() public {
        if (lpAddress == address(0)) updateAddresses();

        if (stakers[msg.sender].stakingAmount <= 0) return;

        uint256 _pending_ = pendingReward(msg.sender);

        if (_pending_ == 0) return;

        IERC20(lpAddress).transfer(msg.sender, _pending_);
        stakers[msg.sender].rewardDebt = stakers[msg.sender].boostedAmount
            .mul(_accLPPerShare)
            .div(_dividendsPerShareAccuracyFactor);

        updateRewardPool();

        emit ClaimRewards(msg.sender, _pending_);
    }

    /**
     * compound function for LP stakers
     @notice stakers restake claimable LP every 24 hours without staking fee.
     */
    function compound() public {
        if (lpAddress == address(0)) updateAddresses();
        if (stakers[msg.sender].stakingAmount <= 0) return;
        uint256 _pending_ = pendingReward(msg.sender);
        if (_pending_ == 0) return;

        stakers[msg.sender].stakingAmount = stakers[msg.sender].stakingAmount
            .add(_pending_);
        stakers[msg.sender].boostedAmount = stakers[msg.sender].boostedAmount
            .add(_pending_);
        stakers[msg.sender].rewardDebt = stakers[msg.sender].boostedAmount
            .mul(_accLPPerShare)
            .div(_dividendsPerShareAccuracyFactor);

        totalStakingAmount = totalStakingAmount.add(_pending_);
        _totalBoostedAmount = _totalBoostedAmount.add(_pending_);

        emit Compound(msg.sender, _pending_);
    }

    /**
     * unstake function
     @notice stakers have to claim rewards before finishing stake.
     */
    function unstake() public {
        if (lpAddress == address(0) || _LPLockReceiver == address(0))
            updateAddresses();

        uint256 _amount_ = stakers[msg.sender].stakingAmount;
        if (_amount_ <= 0) return;
        require(
            block.timestamp - stakers[msg.sender].lastStakingUpdateTime >=
                stakers[msg.sender].stakingPeriod,
            "Don't finish your staking period!"
        );

        updateRewardPool();
        IERC20(lpAddress).transfer(msg.sender, _amount_.mul(900).div(1000));
        IERC20(lpAddress).transfer(_LPLockReceiver, _amount_.mul(30).div(1000));

        _totalReflection = _totalReflection.add(_amount_.mul(20).div(1000));
        _LPLockAmount = _LPLockAmount.add(_amount_.mul(30).div(1000));
        _totalBoostedAmount = _totalBoostedAmount.sub(
            stakers[msg.sender].boostedAmount
        );
        totalStakingAmount = totalStakingAmount.sub(
            stakers[msg.sender].stakingAmount
        );
        totalStakerNum--;

        stakers[msg.sender].stakingAmount = 0;
        stakers[msg.sender].boostedAmount = 0;
        stakers[msg.sender].lastStakingUpdateTime = block.timestamp;

        _distributeReflectionRewards();

        emit Unstake(msg.sender, _amount_);
    }

    /**
     * register LP holders address
     @notice LP holders have to register their address to get LP reflection.
     */
    function registerAddress() public {
        if (_LPLockReceiver == address(0)) updateAddresses();
        if (msg.sender == _LPLockReceiver) return;
        _LPholderIndexes[msg.sender] = LPholders.length;
        LPholders.push(msg.sender);
    }

    /**
     * remove LP holders address
     */
    function removeShareholder(address _holder) public {
        LPholders[_LPholderIndexes[_holder]] = LPholders[LPholders.length - 1];
        _LPholderIndexes[LPholders[LPholders.length - 1]] = _LPholderIndexes[_holder];
        LPholders.pop();
    }

    /**
     * LP reflection whenever stake and unstake
     */
    function _distributeReflectionRewards() internal {
        if (lpAddress == address(0)) updateAddresses();

        uint256 _totalDividends_ = IERC20(lpAddress).totalSupply()
            .sub(totalStakingAmount)
            .sub(_LPLockAmount);
        uint256 _ReflectionPerShare_ = _totalReflection
            .mul(_dividendsPerShareAccuracyFactor)
            .div(_totalDividends_);

        for (uint256 i = 0; i <= LPholders.length - 1; i++) {
            uint256 _balance_ = IERC20(lpAddress).balanceOf(LPholders[i]);
            if (_balance_ > 0)
                IERC20(lpAddress).transfer(
                    LPholders[i],
                    _ReflectionPerShare_.mul(_balance_).div(
                        _dividendsPerShareAccuracyFactor
                    )
                );
            if (_balance_ == 0) removeShareholder(LPholders[i]);
        }
        _totalReflection = 0;
    }

    function withdraw() external onlyOwner {
        if (lpAddress == address(0)) updateAddresses();
        IERC20(lpAddress).transfer(msg.sender, IERC20(lpAddress).balanceOf(address(this)));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}
