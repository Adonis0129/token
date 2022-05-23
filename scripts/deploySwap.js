const { ethers, upgrades } = require("hardhat");

async function main() {
    const Swap = await ethers.getContractFactory("FurioSwapV1");
    const swap = await upgrades.deployProxy(Swap);
    await swap.deployed();
    console.log("Swap proxy deployed to:", swap.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
