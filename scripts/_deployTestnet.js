const hre = require("hardhat");
const Contract = require("./utils/Contract");
require("dotenv").config();
const factory = process.env.FACTORY || '';
const router = process.env.ROUTER || '';
const safe = process.env.SAFE || '';

const main = async () => {
    let contract = new Contract();
    // Deploy AddressBook
    const addressbook = await contract.deploy("AddressBook");
    console.log("AddressBook deployed to", addressbook.address);
    let tx = await addressbook.set("factory", factory);
    await tx.wait();
    tx = await addressbook.set("router", router);
    await tx.wait();
    tx = await addressbook.set("safe", safe);
    await tx.wait();
    console.log("Factory, router, and safe adddresses set");
    // Re instantiate contract with new addressbook
    contract = new Contract(addressbook.address);
    // Deploy Token
    const token = await contract.deploy("TokenV1", "token");
    console.log("Token deployed to", token.address);
    // Deploy USDC
    const usdc = await contract.deploy("FakeToken", "payment", ["USD Coin", "USDC"]);
    console.log("USDC deployed to", usdc.address);
    // Deploy Pool
    const pool = await contract.deploy("Pool", "pool");
    console.log("Pool deployed to", pool.address);
    // Mint USDC to Pool
    tx = await usdc.mintTo(pool.address, 1000000);
    await tx.wait();
    console.log("1,000,000 USDC minted to Pool address");
    // Deploy Liquidity
    tx = await pool.createLiquidity();
    await tx.wait();
    console.log("Liquidity pool created");
    // Deploy Swap
    const swap = await contract.deploy("Swap", "swap");
    console.log("Swap deployed to", swap.address);
    // Deploy Vault
    const vault = await contract.deploy("Vault", "vault");
    console.log("Vault deployed to", vault.address);
    // Deploy Downline
    const downline = await contract.deploy("Downline", "downline");
    console.log("Downline deployed to", downline.address);
    // Deploy AutoCompound
    const autocompound = await contract.deploy("AutoCompoundV2", "autocompound");
    console.log("AutoCompound deployed to", autocompound.address);
    // Deploy FurBetToken
    const furbettoken = await contract.deploy("FurBetToken", "furbettoken");
    console.log("FurBetToken deployed to ", furbettoken.address);
    // Deploy FurBetPresale
    const furbetpresale = await contract.deploy("FurBetPresale", "furbetpresale");
    console.log("FurBetPresale deployed to ", furbetpresale.address);
    // Deploy FurBetStake
    const furbetstake = await contract.deploy("FurBetStake", "furbetstake");
    console.log("FurBetStake deployed to ", furbetstake.address);
    // Deploy AddLiquidity
    const addliquidity = await contract.deploy("AddLiquidity", "addliquidity");
    console.log("AddLiquidity deployed to ", addliquidity.address);
    // Deploy LPStaking
    const lpstaking = await contract.deploy("LPStakingV1", "lpstaking");
    console.log("LPStaking deployed to ", lpstaking.address);
    // DONE!
    console.log("Deployment complete");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
