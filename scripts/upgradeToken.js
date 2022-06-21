const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    const tokenaddress = await addressbook.get("token");
    const Token = await ethers.getContractFactory("Token");
    await upgrades.upgradeProxy(tokenaddress, Token);
    console.log("Token contract upgraded");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
