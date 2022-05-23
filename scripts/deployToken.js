const { ethers, upgrades } = require("hardhat");

const TokenContract = "FurioTokenV1";

async function main() {
    const Token = await ethers.getContractFactory(TokenContract);
    const token = await upgrades.deployProxy(Token);
    await token.deployed();
    console.log("Token proxy deployed to:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
