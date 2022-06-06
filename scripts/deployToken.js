const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const Token = await ethers.getContractFactory("Token");
    const token = await upgrades.deployProxy(Token);
    await token.deployed();
    await token.setAddressBook(addressBook);
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    await addressbook.set('token', token.address);
    //await token.mintLiquidity();
    console.log("Token proxy deployed to:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
