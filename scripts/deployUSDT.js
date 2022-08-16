const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    // deploy token
    const USDT = await ethers.getContractFactory("USDT");
    const usdt = await upgrades.deployProxy(USDT);
    await usdt.deployed();
    await usdt.setAddressBook(addressBook);
    await addressbook.set("usdt", usdt.address);
    console.log("USDT proxy deployed to:", usdt.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
