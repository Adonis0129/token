// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "./interfaces/IClaim.sol";
import "./interfaces/IToken.sol";


/**
 * @title Claim
 * @author Steve Harmeyer
 * @notice This contract handles presale NFT claims
 * @dev All percentages are * 100 (e.g. .5% = 50, .25% = 25)
 */

/// @custom:security-contact security@furio.io
contract Vault is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        maxPayout = 100000 * (10 ** 18);
        maxReturn = 36000;
        period = 60; // DEV period is 1 minute.
        //period = 86400 // PRODUCTION period is 24 hours.
        lookback = 86400; // DEV lookback is 1 day.
        //lookback = 2419200; // PRODUCTION lookback is 28 days.
        claimCooldown = 55; // DEV cooldown is 55 seconds.
        //claimCooldown = 83315; // PRODUCTION cooldown is a little shy of a day.
        penaltyLookback = 3600; // DEV penalty lookback is 1 hour
        //penaltyLookback = 604800; // PRODUCTION penalty lookback is 7 days.
        neutralClaims = 13;
        negativeClaims = 15;
        penaltyClaims = 7;
        penaltyRate = 50;
        // Rewards percentages based on 28 day claims.
        rates[0] = 250;
        rates[1] = 225;
        rates[2] = 225;
        rates[3] = 225;
        rates[4] = 225;
        rates[5] = 225;
        rates[6] = 225;
        rates[7] = 225;
        rates[8] = 225;
        rates[9] = 200;
        rates[10] = 200;
        rates[11] = 200;
        rates[12] = 200;
        rates[13] = 200;
        rates[14] = 200;
        rates[15] = 100;
        rates[16] = 100;
        rates[17] = 100;
        rates[18] = 100;
        rates[19] = 100;
        rates[20] = 100;
        rates[21] = 50;
        rates[22] = 50;
        rates[23] = 50;
        rates[24] = 50;
        rates[25] = 50;
        rates[26] = 50;
        rates[27] = 50;
        rates[28] = 50;
    }

    /**
     * Vault properties.
     */
    uint256 public maxPayout; // Max tokens a user can receive.
    uint256 public maxReturn; // Max return percentage.
    uint256 public period; // Seconds for each compound period.
    uint256 public lookback; // Seconds to look back for tier calculation.
    uint256 public claimCooldown; // Cooldown period between actions.
    uint256 public penaltyLookback; // Seconds to look back to calculate permanent penalty.
    uint256 public neutralClaims; // How many claims during period to be considered neutral.
    uint256 public negativeClaims; // How many claims during period to be considered negative.
    uint256 public penaltyClaims; // How many claims during penalty lookback to be get penalized forever.
    uint256 public penaltyRate; // Reward rate for penalized players.
    mapping(uint256 => uint256) public rates;

    /**
     * Player mappings.
     */
    mapping(address => address) public referrer;
    mapping(address => address[]) public referrals;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public initialDeposit;
    mapping(address => uint256) public totalDeposit;
    mapping(address => uint256) public totalClaim;
    mapping(address => uint256[]) public claims;
    mapping(address => bool) public negative;
    mapping(address => bool) public penalized;
    mapping(address => uint256) public lastAction;
    mapping(address => uint256) public lastDeposit;
    mapping(address => uint256) public lastClaim;
    mapping(address => bool) public maxed;
    mapping(address => uint256) public maxedPercent;

    /**
     * Deposit.
     * @param quantity_ Token quantity.
     * @return bool True if successful.
     */
    function deposit(uint256 quantity_) external returns (bool)
    {
        require(_token().transferFrom(msg.sender, address(this), quantity_), "Unable to transfer tokens");
        return depositFor(msg.sender, quantity_);
    }

    /**
     * Deposit with referrer.
     * @param quantity_ Token quantity.
     * @param referrer_ Referrer address.
     * @return bool True if successful.
     */
    function deposit(uint256 quantity_, address referrer_) external returns (bool)
    {
        require(_token().transferFrom(msg.sender, address(this), quantity_), "Unable to transfer tokens");
        return depositFor(msg.sender, quantity_, referrer_);
    }

    /**
     * Deposit for.
     * @param player_ Player address.
     * @param quantity_ Token quantity.
     * @return bool True if successful.
     */
    function depositFor(address player_, uint256 quantity_) public returns (bool)
    {
        if(msg.sender != addressBook.get("claim")) {
            require(_token().transferFrom(player_, address(this), quantity_), "Unable to transfer tokens");
        }
        return _deposit(player_, quantity_);
    }

    /**
     * Deposit for with referrer.
     * @param player_ Player address.
     * @param quantity_ Token quantity.
     * @param referrer_ Referrer address.
     * @return bool True if successful.
     */
    function depositFor(address player_, uint256 quantity_, address referrer_) public returns (bool)
    {
        if(msg.sender != addressBook.get("claim")) {
            require(_token().transferFrom(player_, address(this), quantity_), "Unable to transfer tokens");
        }
        address _safe_ = addressBook.get("safe");
        if(referrer_ == address(0)) {
            referrer_ = _safe_;
        }
        if(referrer[player_] == address(0)) {
            referrer[player_] = referrer_;
            referrals[referrer_].push(player_);
        }
        if(referrer[referrer_] == address(0)) {
            referrer[referrer_] = _safe_;
            referrals[_safe_].push(referrer_);
        }
        return _deposit(player_, quantity_);
    }

    /**
     * Internal deposit.
     * @param player_ Player address.
     * @param quantity_ Token quantity.
     * @return bool True if successful.
     */
    function _deposit(address player_, uint256 quantity_) internal returns (bool)
    {
        require(quantity_ > 0, "Invalid quantity");
        if(startTime[player_] == 0) {
            startTime[player_] = block.timestamp;
            initialDeposit[player_] = quantity_;
        }
        if(referrer[player_] == address(0)) {
            referrer[player_] = addressBook.get("safe");
        }
        lastAction[player_] = block.timestamp;
        lastDeposit[player_] = block.timestamp;
        uint256 _refundAmount_ = 0;
        if(totalDeposit[player_] + quantity_ > maxThreshold()) {
            _refundAmount_ = totalDeposit[player_] + quantity_ - maxThreshold();
        }
        totalDeposit[player_] += quantity_ - _refundAmount_;
        if(_refundAmount_ > 0) {
            IToken _token_ = _token();
            uint256 _balance_ = _token_.balanceOf(address(this));
            if(_balance_ < _refundAmount_) {
                _token_.mint(address(this), _refundAmount_ - _balance_);
            }
            _token_.transfer(player_, _refundAmount_);
        }
        if(totalDeposit[player_] >= maxThreshold()) {
            maxed[player_] = true;
            maxedPercent[player_] = rewardPercent(player_);
        }
        return true;
    }

    /**
     * Reward percent.
     * @param player_ Address of player.
     * @return uint256 Reward percentage.
     */
    function rewardPercent(address player_) public view returns (uint256)
    {
        if(maxed[player_]) {
            return maxedPercent[player_];
        }
        if(penalized[player_]) {
            return penaltyRate;
        }
        return rates[effectiveClaims(player_)];
    }

    /**
     * Effective claims.
     * @param player_ Address of player.
     * @return uint256 Number of "effective" claims.
     * @dev This number may not reflect the actual number of claims, but instead
     * represents the number of claims used to determine participation status and rate.
     */
    function effectiveClaims(address player_) public view returns (uint256)
    {
        uint256 _start_ = block.timestamp - lookback;
        uint256 _penaltyStart_ = block.timestamp - penaltyLookback;
        uint256 _periodClaims_ = 0;
        uint256 _penaltyClaims_ = 0;
        uint256[] memory _claims_ = claims[player_];
        for(uint256 i = 0; i < _claims_.length; i++) {
            if(_claims_[i] <= _start_) {
                continue;
            }
            _periodClaims_ ++;
            if(_claims_[i] <= _penaltyStart_) {
                _penaltyClaims_ ++;
            }
        }
        if(negative[player_] && _periodClaims_ < negativeClaims) {
            _periodClaims_ = negativeClaims;
        }
        if(_periodClaims_ > 28 || _penaltyClaims_ >= penaltyClaims) {
            _periodClaims_ = 28;
        }
        if(startTime[player_] < lookback && _periodClaims_ < neutralClaims) {
            _periodClaims_ = neutralClaims;
        }
        return _periodClaims_;
    }

    /**
     * Reward available.
     * @param player_ Address of player.
     * @return uint256 Amount of reward tokens available
     */
    function rewardAvailable(address player_) public view returns (uint256)
    {
        uint256 _available_ = ((block.timestamp - lastAction[player_]) / period) * (rewardPercent(player_) / 10000) * totalDeposit[player_];
        if(_available_ + totalClaim[player_] > maxPayout) {
            _available_ = maxPayout - totalClaim[player_];
        }
        return _available_;
    }

    /**
     * Claim.
     * @return bool True if successful.
     */
    function claim() external returns (bool)
    {
        return _claim(msg.sender);
    }

    /**
     * Claim.
     * @param player_ Address of player who is claiming.
     * @return bool True if successful.
     */
    function _claim(address player_) internal returns (bool)
    {
        uint256 _available_ = rewardAvailable(player_);
        require(_available_ > 0, "No claims available");
        require(lastClaim[player_] <= block.timestamp - claimCooldown, "Cooldown period in effect");
        lastAction[player_] = block.timestamp;
        lastClaim[player_] = block.timestamp;
        totalClaim[player_] += _available_;
        if(!maxed[player_]) {
            uint256 _claims_ = effectiveClaims(player_);
            if(_claims_ >= negativeClaims) {
                negative[player_] = true;
            }
            if(_claims_ >= 28) {
                penalized[player_] = true;
            }
        }
        IToken _token_ = _token();
        uint256 _balance_ = _token_.balanceOf(address(this));
        if(_balance_ < _available_) {
            _token_.mint(address(this), _available_ - _balance_);
        }
        return _token_.transfer(player_, _available_);
    }

    /**
     * Compound.
     * @return bool True if successful.
     */
    function compound() external returns (bool)
    {
        return _compound(msg.sender);
    }

    /**
     * Compound.
     * @param player_ Address of player.
     * @return bool True if successful.
     */
    function _compound(address player_) internal returns (bool)
    {
        uint256 _available_ = rewardAvailable(player_);
        require(_available_ > 0, "No rewards available");
        lastAction[player_] = block.timestamp;
        lastDeposit[player_] = block.timestamp;
        return _deposit(player_, _available_);
    }

    /**
     * Max threshold.
     * @return uint256 Number of tokens needed to be considered at max.
     */
    function maxThreshold() public view returns (uint256)
    {
        return maxPayout / maxReturn;
    }

    /**
     * Get token contract.
     * @return IToken Token contract.
     */
    function _token() internal view returns (IToken)
    {
        return IToken(addressBook.get("token"));
    }
}
