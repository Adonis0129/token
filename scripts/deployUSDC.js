const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    // deploy token
    const USDC = await ethers.getContractFactory("USDC");
    const usdc = await upgrades.deployProxy(USDC);
    await usdc.deployed();
    await usdc.setAddressBook(addressBook);
    await addressbook.set("payment", usdc.address);
    console.log("USDC proxy deployed to:", usdc.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
