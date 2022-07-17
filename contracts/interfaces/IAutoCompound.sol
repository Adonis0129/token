// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAutoCompound {
    struct Properties {
        uint256 maxPeriods; // Maximum number of periods a participant can auto compound.
        uint256 period; // Seconds between compounds.
        uint256 fee; // BNB fee per period of auto compounding.
        uint256 minPresaleBalance; // Minimum number of presale NFTs a user needs to hold to participate.
        uint256 minVaultBalance; // Minimum vault balance a user needs to participate.
        uint256 maxParticipants; // Maximum autocompound participants.
    }
    struct Stats {
        uint256 compounding; // Number of participants auto compounding.
        uint256 compounds; // Number of auto compounds performed.
    }
    function addressBook (  ) external view returns ( address );
    function compound ( uint256 quantity_ ) external;
    function compound ( ) external;
    function compoundAll (  ) external;
    function compounding (  ) external view returns ( address[] memory );
    function compounds ( address participant_ ) external view returns ( uint256[] memory );
    function compoundsLeft ( address participant_ ) external view returns ( uint256 );
    function due (  ) external view returns ( uint256 );
    function end (  ) external returns ( bool );
    function initialize (  ) external;
    function lastCompound ( address participant_ ) external view returns ( uint256 );
    function next (  ) external view returns ( address );
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function properties (  ) external view returns ( Properties memory );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function start ( uint256 periods_ ) external returns ( bool );
    function stats (  ) external view returns ( Stats memory );
    function totalCompounds ( address participant_ ) external view returns ( uint256 );
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}
