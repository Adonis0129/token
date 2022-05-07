const { ethers, upgrades } = require("hardhat");

describe("Token", function () {
    it("Deploys", async function () {
        const Token = await ethers.getContractFactory("Token");
        await upgrades.deployProxy(Token, { kind: 'uups' });
    });
});
