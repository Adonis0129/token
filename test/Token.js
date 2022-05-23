const { expect, use } = require("chai");
const { solidity } = require("ethereum-waffle");
const { ethers, upgrades } = require("hardhat");
use(solidity);

const TokenContract = "FurioTokenV1";

describe("FurioToken", function () {
    // RUN THIS BEFORE EACH TEST
    beforeEach(async function () {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        const Token = await ethers.getContractFactory(TokenContract);
        const token = await upgrades.deployProxy(Token);
    });
    it("Deploys", async function () {
    });
});
