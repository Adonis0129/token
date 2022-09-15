const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    const taxhandleraddress = await addressbook.get("taxHandler");
    const TaxHandler = await ethers.getContractFactory("TaxHandler");
    await upgrades.upgradeProxy(taxhandleraddress, TaxHandler);
    console.log("TaxHandler contract upgraded", taxhandleraddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
