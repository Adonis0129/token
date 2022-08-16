const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    // deploy LP Staking
    const LPSwap = await ethers.getContractFactory("LPSwap");
    const lpswap = await upgrades.deployProxy(LPSwap);
    await lpswap.deployed();
    await new Promise(r => setTimeout(r, 10000));
    await lpswap.setAddressBook(addressBook);
    await new Promise(r => setTimeout(r, 10000));
    await addressbook.set("lpSwap", lpswap.address);
    usdc = await addressbook.get("payment");
    wbnb = await addressbook.get("wbnb");
    usdt = await addressbook.get("usdt");
    await new Promise(r => setTimeout(r, 10000));
    await lpswap.setSwapPathFromTokenToUSDC(wbnb, [
      wbnb,
      usdc,
    ]);
    await new Promise(r => setTimeout(r, 10000));
    await lpswap.setSwapPathFromTokenToUSDC(usdt, [
      usdt,
      usdc,
    ]);
    console.log("LPSwap proxy deployed to:", lpswap.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
