// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVault {
    function addressBook (  ) external view returns ( address );
    function claim (  ) external returns ( bool );
    function claimPrecheck ( address participant_ ) external view returns ( uint256 );
    function compound (  ) external returns ( bool );
    function deposit ( uint256 quantity_, address referrer_ ) external returns ( bool );
    function deposit ( uint256 quantity_ ) external returns ( bool );
    function depositFor ( address participant_, uint256 quantity_ ) external returns ( bool );
    function depositFor ( address participant_, uint256 quantity_, address referrer_ ) external returns ( bool );
    function initialize (  ) external;
    function owner (  ) external view returns ( address );
    function participantStatus ( address participant_ ) external view returns ( uint256 );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function updateLookbackPeriods ( uint256 lookbackPeriods_ ) external;
    function updateMaxPayout ( uint256 maxPayout_ ) external;
    function updateMaxReturn ( uint256 maxReturn_ ) external;
    function updateNegativeClaims ( uint256 negativeClaims_ ) external;
    function updateNeutralClaims ( uint256 neutralClaims_ ) external;
    function updatePenaltyClaims ( uint256 penaltyClaims_ ) external;
    function updatePenaltyLookbackPeriods ( uint256 penaltyLookbackPeriods_ ) external;
    function updatePeriod ( uint256 period_ ) external;
    function updateRate ( uint256 claims_, uint256 rate_ ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}
