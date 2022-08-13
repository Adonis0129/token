// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";

// Interfaces.
import "./interfaces/IToken.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title LP buy and sell
 * @author Steve Harmeyer
 * @notice This contrac make users can buy LP with any token and get USDC by selling LP.
 */

/// @custom:security-contact security@furio.io
contract LPSwap is BaseContract {
    // is necessary to receive unused bnb from the swaprouter
    receive() external payable {}

    address _routerAddress;
    address _tokenAddress;
    address _usdcAddress;
    address _lpAddress;
    IUniswapV2Router02 public router;
    mapping(address => address[]) public pathFromTokenToUSDC;

    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() public initializer {
        __BaseContract_init();
    }

    /**
     * Set Swap router path to swap any token to USDC
     * @param token_ token address to swap
     * @param pathToUSDC_ path address array
     */
    function setSwapPathFromTokenToUSDC(
        address token_,
        address[] memory pathToUSDC_
    ) public onlyOwner {

        if (_usdcAddress == address(0)) updateAddresses();

        require(token_ != address(0), "Invalid token address");
        require(pathToUSDC_.length >= 2, "Invalid path length");
        require(pathToUSDC_[0] == token_, "Invalid starting token");
        require(pathToUSDC_[pathToUSDC_.length - 1] == _usdcAddress,"Invalid ending token");

        pathFromTokenToUSDC[token_] = pathToUSDC_;
    }

    /**
     * Update addresses.
     * @dev Updates stored addresses.
     */
    function updateAddresses() public {

        IUniswapV2Factory _factory_ = IUniswapV2Factory(addressBook.get("factory"));
        _lpAddress = _factory_.getPair(
            addressBook.get("payment"),
            addressBook.get("token")
        );
        _routerAddress = addressBook.get("router");
        _tokenAddress = addressBook.get("token");
        _usdcAddress = addressBook.get("payment");
    }

    /**
     * buy LP with any token
     * @param paymentAddress_ token address that user is going to buy LP
     * @param paymentAmount_ token amount that user is going to buy LP
     * @return lpAmount_ LP amount that user received
     * @return unusedPaymentToken_ USDC amount that don't used to buy LP
     * @return unusedToken_ token amount that don't used to buy LP
     * @dev approve token before buyLP
     */
    function buyLP(address paymentAddress_, uint256 paymentAmount_)
        public
        payable
        returns (
            uint256 lpAmount_,
            uint256 unusedPaymentToken_,
            uint256 unusedToken_
        )
    {

        if (_routerAddress == address(0) || _usdcAddress == address(0)) updateAddresses();
        router = IUniswapV2Router02(_routerAddress);
        IERC20 _usdc_ = IERC20(_usdcAddress);
        require(address(paymentAddress_) != address(0), "Invalid Address");
        IERC20 _payment_ = IERC20(paymentAddress_);

        if(paymentAddress_ == router.WETH()){
            require(msg.value >= paymentAmount_, "Invalid amount");

            address[] memory _pathFromEthToUSDC = pathFromTokenToUSDC[paymentAddress_];
            require(_pathFromEthToUSDC.length >=2, "Don't exist path");
            uint256 _USDCBalanceBefore_ = _usdc_.balanceOf(address(this));
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: paymentAmount_}(
                0, 
                _pathFromEthToUSDC, 
                address(this), 
                block.timestamp + 1
            );
            uint256 _USDCBalance_ = _usdc_.balanceOf(address(this)) - _USDCBalanceBefore_;

            (lpAmount_, unusedPaymentToken_, unusedToken_) = _buyLPwithUSDC(_USDCBalance_);
            return (lpAmount_, unusedPaymentToken_, unusedToken_);

        }
        else
        {
            require(_payment_.balanceOf(msg.sender) >= paymentAmount_,"Invalid amount");
            _payment_.transferFrom(msg.sender, address(this), paymentAmount_);

            if (paymentAddress_ == _usdcAddress) {

                (lpAmount_, unusedPaymentToken_, unusedToken_) = _buyLPwithUSDC(paymentAmount_);
                return (lpAmount_, unusedPaymentToken_, unusedToken_);
            }
            
            address[] memory _pathFromTokenToUSDC = pathFromTokenToUSDC[paymentAddress_];
            require(_pathFromTokenToUSDC.length >=2, "Don't exist path");
            _payment_.approve(address(router), paymentAmount_);
            uint256 _USDCBalanceBefore1_ = _usdc_.balanceOf(address(this));
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                paymentAmount_,
                0, 
                _pathFromTokenToUSDC, 
                address(this), 
                block.timestamp + 1
            );
            uint256 _USDCBalance1_ = _usdc_.balanceOf(address(this)) - _USDCBalanceBefore1_;

            (lpAmount_, unusedPaymentToken_, unusedToken_) = _buyLPwithUSDC(_USDCBalance1_);
            return (lpAmount_, unusedPaymentToken_, unusedToken_);
        }
    }

    /**
     * buy LP with USDC
     * @param paymentAmount_ USDC amount that user is going to buy LP
     * @return lpAmount_ LP amount that user received
     * @return unusedPaymentToken_ USDC amount that don't used to buy LP
     * @return unusedToken_ Token amount that don't used to buy LP
     * @notice buyer can get unused USDC and token automatically
     */
    function _buyLPwithUSDC(uint256 paymentAmount_)
        internal
        returns (
            uint256 lpAmount_,
            uint256 unusedPaymentToken_,
            uint256 unusedToken_
        )
    {
        if (
            _routerAddress == address(0) ||
            _tokenAddress == address(0) ||
            _usdcAddress == address(0)
        ) updateAddresses();

        IERC20 _usdc_ = IERC20(_usdcAddress);
        IToken _token_ = IToken(_tokenAddress);
        router = IUniswapV2Router02(_routerAddress);
        require(address(_usdc_) != address(0), "Payment token not set");
        require(address(_token_) != address(0), "Token not set");
        require(address(router) != address(0), "Router not set");

        uint256 _amountToLiquify_ = paymentAmount_ / 2;
        uint256 _amountToSwap_ = paymentAmount_ - _amountToLiquify_;
        if (_amountToSwap_ == 0) return (0, 0, 0);

        address[] memory _path_ = new address[](2);
        _path_[0] = address(_usdc_);
        _path_[1] = address(_token_);
        _usdc_.approve(address(router), _amountToSwap_);
        uint256 _balanceBefore_ = _token_.balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountToSwap_,
            0,
            _path_,
            address(this),
            block.timestamp + 1
        );
        uint256 _amountToken_ = _token_.balanceOf(address(this)) -_balanceBefore_;

        if (_amountToLiquify_ <= 0 || _amountToken_ <= 0) return (0, 0, 0);
        _usdc_.approve(address(router), _amountToLiquify_);
        _token_.approve(address(router), _amountToken_);

        (
            uint256 _usedPaymentToken_,
            uint256 _usedToken_,
            uint256 _lpValue_
        ) = router.addLiquidity(
                address(_usdc_),
                address(_token_),
                _amountToLiquify_,
                _amountToken_,
                0,
                0,
                msg.sender,
                block.timestamp + 1
            );
        lpAmount_ = _lpValue_;
        unusedPaymentToken_ = _amountToLiquify_ - _usedPaymentToken_;
        unusedToken_ = _amountToken_ - _usedToken_;

        // send back unused tokens
        _usdc_.transfer(msg.sender, unusedPaymentToken_);
        _token_.transfer(msg.sender, unusedToken_);
    }

    /**
     * Sell LP
     * @param lpAmount_ LP amount that user is going to sell
     * @return paymentAmount_ USDC amount that user received
     * @dev approve LP before this function calling
     */
    function sellLP(uint256 lpAmount_) public returns (uint256 paymentAmount_) {
        if (
            _routerAddress == address(0) ||
            _tokenAddress == address(0) ||
            _usdcAddress == address(0) ||
            _lpAddress == address(0)
        ) updateAddresses();

        IERC20 _usdc_ = IERC20(_usdcAddress);
        IERC20 _token_ = IERC20(_tokenAddress);
        router = IUniswapV2Router02(_routerAddress);
        IERC20 _lptoken_ = IERC20(_lpAddress);
        require(address(_usdc_) != address(0), "Payment not set");
        require(address(_token_) != address(0), "Token not set");
        require(address(router) != address(0), "Router not set");
        require(address(_lptoken_) != address(0), "_lptoken_ not set");

        require(_lptoken_.balanceOf(msg.sender) >= lpAmount_, "Invalid amount");
        _lptoken_.transferFrom(msg.sender, address(this), lpAmount_);

        if (lpAmount_ <= 0) return 0;

        _lptoken_.approve(address(router), lpAmount_);
        uint256 _tokenBalanceBefore_ = _token_.balanceOf(address(this));
        (uint256 _USDCFromRemoveLiquidity_, ) = router.removeLiquidity(
            address(_usdc_),
            address(_token_),
            lpAmount_,
            0,
            0,
            address(this),
            block.timestamp + 1
        );

        uint256 _tokenBalance_ = _token_.balanceOf(address(this)) -_tokenBalanceBefore_;
        if (_tokenBalance_ == 0) return 0;

        _token_.approve(address(router), _tokenBalance_);
        address[] memory path = new address[](2);
        path[0] = address(_token_);
        path[1] = address(_usdc_);
        uint256 _USDCbalanceBefore_ = _usdc_.balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenBalance_,
            0,
            path,
            address(this),
            block.timestamp + 1
        );
        uint256 _USDCFromSwap = _usdc_.balanceOf(address(this)) -
            _USDCbalanceBefore_;

        _usdc_.transfer(msg.sender, _USDCFromRemoveLiquidity_ + _USDCFromSwap);

        paymentAmount_ = _USDCFromRemoveLiquidity_ + _USDCFromSwap;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}
