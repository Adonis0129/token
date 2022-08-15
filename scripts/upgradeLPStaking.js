const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    const lpstakingaddress = await addressbook.get("lpstaking");
    const LPStaking = await ethers.getContractFactory("LPStaking");
    await upgrades.upgradeProxy(lpstakingaddress, LPStaking);
    console.log("LPStaking contract upgraded", lpstakingaddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
