// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    /**
     * Token metadata.
     */
    string private _name = 'USDC';
    string private _symbol = 'USDC';

    /**
     * Contract constructor.
     */
    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, 2500000000000000000000000);
    }

    /**
     * Public mint function... mint as many as you want!
     */
    function mint(address to_, uint256 amount_) external {
        super._mint(to_, amount_);
    }
}
