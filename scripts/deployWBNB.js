const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    // deploy token
    const WBNB = await ethers.getContractFactory("WBNB");
    const wbnb = await upgrades.deployProxy(WBNB);
    await wbnb.deployed();
    await wbnb.setAddressBook(addressBook);
    await addressbook.set("wbnb", wbnb.address);
    console.log("WBNB proxy deployed to:", wbnb.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
