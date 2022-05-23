const { ethers } = require("hardhat");

async function main() {
    const USDC = await ethers.getContractFactory("USDC");
    const usdc = await USDC.deploy();
    console.log("USDC deployed to:", usdc.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
