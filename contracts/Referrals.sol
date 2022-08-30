// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";

/**
 * @title Furio Referrals
 * @author Steve Harmeyer
 * @notice This contract keeps track of referrals and referral rewards.
 */

/// @custom:security-contact security@furio.io
contract Referrals is BaseContract
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
     * Addresses.
     */
    address devWallet;

    /**
     * Referrals.
     */
    mapping(address => address) public referrer;
    mapping(address => uint256) public referralCount;
    mapping(address => address[]) public referrals;
    mapping(address => address) public lastRewarded;

    /**
     * Update addresses.
     */
    function updateAddresses() public
    {
        if(devWallet == address(0)) devWallet = addressBook.get("safe");
    }

    /**
     * Add participant.
     * @param participant_ Participant address.
     */
    function addParticipant(address participant_) external
    {
        require(devWallet != address(0), "Dev wallet not yet set");
        _addParticipant(participant_, devWallet);
    }

    /**
     * Add participant.
     * @param participant_ Participant address.
     * @param referrer_ Referrer address.
     */
    function addParticipant(address participant_, address referrer_) external
    {
        _addParticipant(participant_, referrer_);
    }

    /**
     * Internal add participant.
     * @param participant_ Participant address.
     * @param referrer_ Referrer address.
     */
    function _addParticipant(address participant_, address referrer_) internal
    {
        require(devWallet != address(0), "Dev wallet not yet set");
        require(participant_ != address(0), "Participant address is 0");
        require(referrer_ != address(0), "Referrer address is 0");
        require(participant_ != referrer_, "Participant cannot be referrer");
        if(referrer_ != devWallet) require(referrer[referrer_] != address(0), "Referrer does not exist");
        referrer[participant_] = referrer_;
        referralCount[referrer_] ++;
        referrals[referrer_].push(participant_);
    }
}
