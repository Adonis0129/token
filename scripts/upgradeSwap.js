const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    const swapaddress = await addressbook.get("swap");
    const Swap = await ethers.getContractFactory("SwapV2");
    await upgrades.upgradeProxy(swapaddress, Swap);
    console.log("Swap contract upgraded", swapaddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
