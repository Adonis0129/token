const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const addressBook = process.env.ADDRESS_BOOK || '';

async function main() {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    const AddressBook = await ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.attach(addressBook);
    const usdcaddress = await addressbook.get("payment");
    const furaddress = await addressbook.get("token");
    const swapaddress = await addressbook.get("swap");
    const USDC = await ethers.getContractFactory("FakeToken");
    const usdc = await USDC.attach(usdcaddress);
    const FUR = await ethers.getContractFactory("TokenV1");
    const fur = await FUR.attach(furaddress);
    const Swap = await ethers.getContractFactory("SwapV2");
    const swap = await Swap.attach(swapaddress);
    let tx = await usdc.mint("1000");
    await tx.wait();
    tx = await usdc.approve(swapaddress, "1000000000000000000000");
    await tx.wait();
    tx = await swap.buy(usdcaddress, "1000");
    await tx.wait();
    const furBalance = await fur.balanceOf(owner.address);
    tx = await fur.approve(swapaddress, furBalance);
    await tx.wait();
    tx = await swap.sell(furBalance);
    await tx.wait();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
