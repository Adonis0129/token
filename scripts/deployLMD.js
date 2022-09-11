const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const LMD = await ethers.getContractFactory("LMD");
    const lmd = await upgrades.deployProxy(LMD);
    await lmd.deployed();
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = AddressBook.attach(addressBook);
    await addressbook.set('lms', lmd.address);
    console.log("LMD proxy deployed to:", lmd.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
