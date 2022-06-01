// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "./interfaces/IPresale.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IVault.sol";

/**
 * @title Claim
 * @author Steve Harmeyer
 * @notice This contract handles presale NFT claims
 */

/// @custom:security-contact security@furio.io
contract Claim is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * NFT Values.
     */
    mapping(uint256 => uint256) private _value;

    /**
     * Empty NFTs.
     */
    mapping(uint256 => bool) private _empty;

    /**
     * Get remaining NFT value.
     * @param tokenId_ ID for the NFT.
     * @return uint256 Value.
     */
    function getTokenValue(uint256 tokenId_) public view returns (uint256)
    {
        IPresale _presale_ = _presale();
        require(address(_presale_) != address(0), "Presale contract not found");
        if(_value[tokenId_] != 0) {
            return _value[tokenId_];
        }
        if(_empty[tokenId_]) {
            return 0;
        }
        return _presale_.tokenValue(tokenId_);
    }

    /**
     * Get total value for an owner.
     * @param owner_ Token owner.
     * @return uint256 Value.
     */
    function getOwnerValue(address owner_) external view returns (uint256)
    {
        IPresale _presale_ = _presale();
        require(address(_presale_) != address(0), "Presale contract not found");
        uint256 _balance_ = _presale_.balanceOf(owner_);
        require(_balance_ > 0, "No NFTs owned");
        uint256 _value_;
        for(uint256 i = 1; i <= _balance_; i++) {
            _value_ += getTokenValue(_presale_.tokenOfOwnerByIndex(owner_, i - 1));
        }
        return _value_;
    }

    /**
     * Owned NFTs.
     * @param owner_ Owner address.
     * @return uint256[] Array of owned tokens.
     */
    function owned(address owner_) external view returns (uint256[] memory)
    {
        IPresale _presale_ = _presale();
        require(address(_presale_) != address(0), "Presale contract not found");
        uint256 _balance_ = _presale_.balanceOf(owner_);
        require(_balance_ > 0, "No NFTs owned");
        uint256[] memory _owned_;
        for(uint256 i = 1; i <= _balance_; i++) {
            _owned_[i - 1] = _presale_.tokenOfOwnerByIndex(owner_, i - 1);
        }
        return _owned_;
    }

    /**
     * Claim NFT.
     * @param tokenId_ ID of the NFT to claim.
     * @param quantity_ Quantity of $FUR to claim.
     * @param address_ Address tokens should be assigned to.
     * @param vault_ Send tokens straight to vault.
     * @return bool True if successful.
     */
    function claimNft(uint256 tokenId_, uint256 quantity_, address address_, bool vault_) external returns (bool)
    {
        require(!_empty[tokenId_], "Token has already been claimed");
        IPresale _presale_ = _presale();
        require(address(_presale_) != address(0), "Presale contract not found");
        IToken _token_ = _token();
        require(address(_token_) != address(0), "Token contract not found");
        IVault _vault_ = _vault();
        require(address(_vault_) != address(0), "Vault contract not found");
        require(!_token_.paused(), "Token is paused");
        require(!_vault_.paused(), "Vault is paused");
        require(_presale_.ownerOf(tokenId_) == msg.sender, "Invalid token id");
        uint256 _value_ = _presale_.tokenValue(tokenId_);
        if(_value[tokenId_] == 0 && _empty[tokenId_] == false) {
            _value[tokenId_] = _value_;
        }
        require(_value[tokenId_] <= quantity_, "Insufficient token value");
        _value[tokenId_] -= quantity_;
        if(_value[tokenId_] == 0) {
            _empty[tokenId_] = true;
        }
        if(vault_) {
            return _vault_.deposit(address_, quantity_);
        }
        _token_.mint(address_, quantity_);
        return true;
    }

    /**
     * Get presale NFT contract.
     * @return IPresale Presale contract.
     */
    function _presale() internal view returns (IPresale)
    {
        return IPresale(addressBook.get("presale"));
    }

    /**
     * Get token contract.
     * @return IToken Token contract.
     */
    function _token() internal view returns (IToken)
    {
        return IToken(addressBook.get("token"));
    }

    /**
     * Get vault contract.
     * @return IVault Vault contract.
     */
    function _vault() internal view returns (IVault)
    {
        return IVault(addressBook.get("vault"));
    }
}
