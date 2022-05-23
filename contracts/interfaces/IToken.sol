// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IToken {
    function allowance ( address owner_, address spender_ ) external view returns ( uint256 );
    function approve ( address spender_, uint256 amount_ ) external returns ( bool );
    function balanceOf ( address account_ ) external view returns ( uint256 );
    function decimals (  ) external view returns ( uint8 );
    function decreaseAllowance ( address spender_, uint256 subtractedValue_ ) external returns ( bool );
    function increaseAllowance ( address spender_, uint256 addedValue_ ) external returns ( bool );
    function initialize (  ) external;
    function name (  ) external view returns ( string memory );
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function symbol (  ) external view returns ( string memory );
    function totalSupply (  ) external view returns ( uint256 );
    function transfer ( address to_, uint256 amount_ ) external returns ( bool );
    function transferFrom ( address from_, address to_, uint256 amount_ ) external returns ( bool );
    function transferOwnership ( address newOwner_ ) external;
    function unpause (  ) external;
    function upgradeTo ( address newImplementation_ ) external;
    function upgradeToAndCall ( address newImplementation_, bytes memory data_ ) external;
    function version (  ) external pure returns ( uint256 );
}
