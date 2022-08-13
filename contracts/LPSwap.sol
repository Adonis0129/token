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
 * @notice This contrac make users can buy and sell LP with USDC.
 */

/// @custom:security-contact security@furio.io
contract LPSwap is BaseContract
{

    // is necessary to receive unused bnb from the swaprouter
    receive() external payable {}

    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    function buyLP(uint256 paymentAmount_) public returns(uint256 lpAmount_)
    {
        IERC20 _payment_ = IERC20(addressBook.get("payment"));
        require(_payment_.balanceOf(msg.sender) >= paymentAmount_, "Invalid amount");
        _payment_.transferFrom(msg.sender, address(this), paymentAmount_);

        lpAmount_ = _buyLPwithUSDC(paymentAmount_);
        return lpAmount_;
    }

    function _buyLPwithUSDC(uint256 paymentAmount_) internal returns(uint256 amountLP_){
        IERC20 _in_ = IERC20(addressBook.get("payment"));
        require(address(_in_) != address(0), "Payment not set");
        IERC20 _out_ = IERC20(addressBook.get("token"));
        require(address(_out_) != address(0), "Token not set");

        uint256 _amountToLiquify_ = paymentAmount_ / 2;
        uint256 _amountToSwap_ = paymentAmount_ - _amountToLiquify_;
        if(_amountToSwap_ == 0) return 0;
        uint256 _amountToken_ = _swap(_in_, _out_, _amountToSwap_);
        amountLP_ = _addLiquidity(_amountToLiquify_, _amountToken_);
        return amountLP_;
    }

    function _swap(IERC20 in_, IERC20 out_, uint256 amount_) internal returns (uint256 amountOut_)
    {
        IUniswapV2Router02 _router_ = IUniswapV2Router02(addressBook.get("router"));
        require(address(_router_) != address(0), "Router not set");
        if(amount_ <= 0) return 0;

        address[] memory _path_ = new address[](2);
        _path_[0] = address(in_);
        _path_[1] = address(out_);
        in_.approve(address(_router_), amount_);
        uint256 _balanceBefore_ = out_.balanceOf(address(this));

        _router_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount_,
            0,
            _path_,
            address(this),
            block.timestamp
        );
        amountOut_ = out_.balanceOf(address(this)) - _balanceBefore_;
        return amountOut_;
    }

    function _addLiquidity(uint256 amountPayment_, uint256 amountToken_) internal returns(uint256 lpAmount_)
    {
        IERC20 _payment_ = IERC20(addressBook.get("payment"));
        IToken _token_ = IToken(addressBook.get("token"));
        IUniswapV2Router02 _router_ = IUniswapV2Router02(addressBook.get("router"));
        require(address(_payment_) != address(0), "Payment token not set");
        require(address(_token_) != address(0), "Token not set");
        require(address(_router_) != address(0), "Router not set");
        if(amountPayment_ <= 0 || amountToken_ <= 0) return 0;

        _payment_.approve(address(_router_), amountPayment_);
        _token_.approve(address(_router_), amountToken_);
        (,, lpAmount_) = _router_.addLiquidity(
            address(_payment_),
            address(_token_),
            amountPayment_,
            amountToken_,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        return lpAmount_;
    }

    function sellLP(uint256 lpAmount_) public returns(uint256 paymentAmount_)
    {
        IUniswapV2Factory _factory_ = IUniswapV2Factory(addressBook.get("factory"));
        address _lpAddress_ = _factory_.getPair(
            addressBook.get("payment"),
            addressBook.get("token")
        );

        require(IERC20(_lpAddress_).balanceOf(msg.sender) >= lpAmount_, "Invalid amount");
        IERC20(_lpAddress_).transferFrom(msg.sender, address(this), lpAmount_);

        paymentAmount_ =  _sellLPWithUSDC(lpAmount_);
        return paymentAmount_;
    }

    function _sellLPWithUSDC(uint256 lpAmount_) internal returns(uint256 paymentAmount_){
        IERC20 _payment_ = IERC20(addressBook.get("payment"));
        require(address(_payment_) != address(0), "Payment not set");
        IERC20 _token_ = IERC20(addressBook.get("token"));
        require(address(_token_) != address(0), "Token not set");
        IUniswapV2Router02 _router_ = IUniswapV2Router02(addressBook.get("router"));
        require(address(_router_) != address(0), "Router not set");
        IUniswapV2Factory _factory_ = IUniswapV2Factory(addressBook.get("factory"));
        address _lpAddress_ = _factory_.getPair(
            addressBook.get("payment"),
            addressBook.get("token")
        );
        IERC20 _lptoken_ = IERC20(_lpAddress_);
        require(address(_lptoken_) != address(0), "_lptoken_ not set");

        if(lpAmount_ <= 0) return 0;
        _lptoken_.approve(address(_router_), lpAmount_);
        uint256 _tokenBalanceBefore_ = _token_.balanceOf(address(this));
        (uint256 _USDCFromRemoveLiquidity_,) = _router_.removeLiquidity(
            address(_payment_),
            address(_token_),
            lpAmount_,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 _tokenBalance_ = _token_.balanceOf(address(this)) - _tokenBalanceBefore_;
        if(_tokenBalance_ == 0) return 0;
        _token_.approve(address(_router_), _tokenBalance_);
        address[] memory path = new address[](2);
        path[0] = address(_token_);
        path[1] = address(_payment_);

        uint256 _USDCbalanceBefore_ = _payment_.balanceOf(address(this));
        _router_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenBalance_,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 _USDCFromSwap = _payment_.balanceOf(address(this)) -_USDCbalanceBefore_;

        _payment_.transfer(msg.sender, _USDCFromRemoveLiquidity_ + _USDCFromSwap);

        return _USDCFromRemoveLiquidity_ + _USDCFromSwap;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}
