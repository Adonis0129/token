const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    // deploy LP Staking
    const LPStaking = await ethers.getContractFactory("LPStaking");
    const lpstaking = await upgrades.deployProxy(LPStaking);
    await lpstaking.deployed();
    await lpstaking.setAddressBook(addressBook);
    await addressbook.set("lpRewardPool", lpstaking.address);
    const safeAddress = await addressbook.get("safe");
    await addressbook.set("lpLockReceiver", safeAddress);
    console.log("LPStaking proxy deployed to:", lpstaking.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
