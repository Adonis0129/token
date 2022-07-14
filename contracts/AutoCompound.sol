// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// INTERFACES
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @title AutoCompound
 * @author Steve Harmeyer
 * @notice This is the auto compound contract.
 */

/// @custom:security-contact security@furio.io
contract AutoCompound is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        _properties.maxPeriods = 7;
        _properties.period = 300; // DEV period is 5 minutes.
        //_properties.period = 86400; // PRODUCTION period is 24 hours.
        _properties.fee = 2000000000000000; // .002 BNB per period.
        _properties.minPresaleBalance = 1; // Must hold 1 presale NFT to participate.
        _properties.minVaultBalance = 100e18; // Must have a vault balance of 100 FUR to participate.
        _properties.maxParticipants = 100; // 100 maximum participants.
    }

    /**
     * Properties.
     */
    struct Properties {
        uint256 maxPeriods; // Maximum number of periods a participant can auto compound.
        uint256 period; // Seconds between compounds.
        uint256 fee; // BNB fee per period of auto compounding.
        uint256 minPresaleBalance; // Minimum number of presale NFTs a user needs to hold to participate.
        uint256 minVaultBalance; // Minimum vault balance a user needs to participate.
        uint256 maxParticipants; // Maximum autocompound participants.
    }
    Properties private _properties;

    /**
     * Stats.
     */
    struct Stats {
        uint256 compounding; // Number of participants auto compounding.
        uint256 compounds; // Number of auto compounds performed.
    }
    Stats private _stats;

    /**
     * Auto compound mappings.
     */
    mapping(address => uint256) private _compoundsLeft;
    mapping(address => uint256) private _lastCompound;
    mapping(address => uint256) private _totalCompounds;
    mapping(address => uint256[]) private _compounds;
    address[] private _compounding;

    /**
     * Get properties.
     * @return Properties Contract properties.
     */
    function properties() external view returns (Properties memory)
    {
        return _properties;
    }

    /**
     * Get stats.
     * @return Stats Contract stats.
     */
    function stats() external view returns (Stats memory)
    {
        return _stats;
    }

    /**
     * Get compounds left.
     * @param participant_ Participant address.
     * @return uint256 Number of compounds remaining.
     */
    function compoundsLeft(address participant_) external view returns (uint256)
    {
        return _compoundsLeft[participant_];
    }

    /**
     * Get last compound.
     * @param participant_ Participant address.
     * @return uint256 Timestamp of last compound.
     */
    function lastCompound(address participant_) external view returns (uint256)
    {
        return _lastCompound[participant_];
    }

    /**
     * Get total compounds.
     * @param participant_ Participant address.
     * @return uint256 Total number of auto compounds.
     */
    function totalCompounds(address participant_) external view returns (uint256)
    {
        return _totalCompounds[participant_];
    }

    /**
     * Get compounds.
     * @param participant_ Participant address.
     * @return uint256[] Array of compound timestamps.
     */
    function compounds(address participant_) external view returns (uint256[] memory)
    {
        return _compounds[participant_];
    }

    /**
     * Get compounding.
     * @return address[] Array of participants auto compounding.
     */
    function compounding() external view returns (address[] memory)
    {
        return _compounding;
    }

    /**
     * Next up.
     * @return address Next address to be compounded.
     * @dev Returns the next address in line that needs to be compounded.
     */
    function next() public view returns (address)
    {
        address _next_ = address(0);
        uint256 _earliestCompound_ = block.timestamp;
        for(uint i = 0; i < _compounding.length; i ++) {
            if(_compoundsLeft[_compounding[i]] > 0 &&
                _lastCompound[_compounding[i]] < _earliestCompound_ &&
                _getVault().availableRewards(_compounding[i]) > 0
            ) {
                _earliestCompound_ = _lastCompound[_compounding[i]];
                _next_ = _compounding[i];
            }
        }
        return _next_;
    }

    /**
     * Due for compound.
     * @return uint256 Number of addresses that are due for compounding.
     */
    function due() public view returns (uint256)
    {
        uint256 _dueCount_ = 0;
        uint256 _dueDate_ = block.timestamp - _properties.period;
        for(uint i = 0; i < _compounding.length; i ++) {
            if(_compoundsLeft[_compounding[i]] > 0 && _lastCompound[_compounding[i]] < _dueDate_) {
                _dueCount_ ++;
            }
        }
        return _dueCount_;
    }

    /**
     * Compound next up.
     * @param count_ Number of compounds to do.
     * @dev Auto compounds next participant.
     */
    function compound(uint256 count_) public
    {
        if(paused()) {
            return;
        }
        address _participant_ = next();
        for(uint i = 1; i <= count_; i ++) {
            if(_participant_ == address(0)) {
                continue;
            }
            _compound(_participant_);
            _participant_ = next();
        }
    }

    /**
     * Compound all
     * @dev Auto compounds all that are due.
     */
    function compoundAll() public
    {
        compound(due());
    }

    /**
     * Internal compound.
     * @dev Auto compounds participant.
     * @return bool True if successful.
     */
    function _compound(address participant_) internal returns (bool)
    {
        if(_compoundsLeft[participant_] == 0) {
            return _end(participant_);
        }
        _lastCompound[participant_] = block.timestamp;
        _compoundsLeft[participant_] --;
        _totalCompounds[participant_] ++;
        _compounds[participant_].push(block.timestamp);
        _stats.compounds ++;
        IVault _vault_ = IVault(addressBook.get("vault"));
        IVault.Participant memory _participant_ = _vault_.getParticipant(msg.sender);
        if(_participant_.maxed) {
            return _end(participant_);
        }
        if(_compoundsLeft[participant_] == 0) {
            _end(participant_);
        }
        _vault_.autoCompound(participant_);
        return true;
    }

    /**
     * Start auto compound.
     * @param periods_ Number of periods to auto compound.
     * @return bool True if successful.
     */
    function start(uint256 periods_) external payable whenNotPaused returns (bool)
    {
        require(msg.value >= periods_ * _properties.fee, "Insufficient message value");
        require(periods_ > 0 && periods_ <= _properties.maxPeriods, "Invalid periods");
        require(_compoundsLeft[msg.sender] == 0, "Participant is already auto compounding");
        require(_compounding.length < _properties.maxParticipants, "Maximum participants reached");
        require(IERC721(addressBook.get("presale")).balanceOf(msg.sender) > 0, "Only presale NFT holders can auto compound");
        IVault _vault_ = IVault(addressBook.get("vault"));
        IVault.Participant memory _participant_ = _vault_.getParticipant(msg.sender);
        require(!_participant_.maxed, "Participant is maxed out");
        require(_participant_.balance >= _properties.minVaultBalance, "Minimum vault balance not met");
        compoundAll();
        _compoundsLeft[msg.sender] = periods_;
        _compounding.push(msg.sender);
        _stats.compounding ++;
        return true;
    }

    /**
     * End auto compound.
     * @return bool True if successful.
     */
    function end() external returns (bool)
    {
        return _end(msg.sender);
    }

    /**
     * Internal end auto compound.
     * @param participant_ Participant address.
     * @return bool True if successful.
     */
    function _end(address participant_) internal returns (bool)
    {
        for(uint i = 0; i < _compounding.length; i ++) {
            if(_compounding[i] == participant_) {
                _stats.compounding --;
                delete _compounding[i];
                break;
            }
        }
        return true;
    }

    /**
     * Get vault.
     * @return IVault Vault contract.
     */
    function _getVault() internal view returns (IVault)
    {
        return IVault(addressBook.get("vault"));
    }

    /**
     * Withdraw.
     */
    function withdraw() external onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }
}
