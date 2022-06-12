const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const EthCrypto = require("eth-crypto");

// PRIVATE KEYS FOR CREATING SIGNATURES
const ownerPrivateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
const addr1PrivateKey = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d';

describe("TestSuite", function () {
    // RUN THIS BEFORE EACH TEST
    beforeEach(async function () {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        AddressBook = await ethers.getContractFactory("AddressBook");
        addressbook = await upgrades.deployProxy(AddressBook);
        await addressbook.deployed();
        await addressbook.set("safe", owner.address);
        Claim = await ethers.getContractFactory("Claim");
        claim = await upgrades.deployProxy(Claim);
        await claim.deployed();
        await claim.setAddressBook(addressbook.address);
        await addressbook.set("claim", claim.address);
        Downline = await ethers.getContractFactory("Downline");
        downline = await upgrades.deployProxy(Downline);
        await downline.deployed();
        await downline.setAddressBook(addressbook.address);
        await addressbook.set("downline", downline.address);
        Payment = await ethers.getContractFactory("Payment");
        payment = await upgrades.deployProxy(Payment);
        await payment.deployed();
        await payment.setAddressBook(addressbook.address);
        await addressbook.set("payment", payment.address);
        Pool = await ethers.getContractFactory("Pool");
        pool = await upgrades.deployProxy(Pool);
        await pool.deployed();
        await pool.setAddressBook(addressbook.address);
        await addressbook.set("pool", pool.address);
        Presale = await ethers.getContractFactory("Presale");
        presale = await Presale.deploy();
        await addressbook.set("presale", presale.address);
        Swap = await ethers.getContractFactory("Swap");
        swap = await upgrades.deployProxy(Swap);
        await swap.deployed();
        await swap.setAddressBook(addressbook.address);
        await addressbook.set("swap", swap.address);
        Token = await ethers.getContractFactory("Token");
        token = await upgrades.deployProxy(Token);
        await token.deployed();
        await token.setAddressBook(addressbook.address);
        await addressbook.set("token", token.address);
        Vault = await ethers.getContractFactory("Vault");
        vault = await upgrades.deployProxy(Vault);
        await vault.deployed();
        await vault.setAddressBook(addressbook.address);
        await addressbook.set("vault", vault.address);
        Verifier = await ethers.getContractFactory("Verifier");
        verifier = await upgrades.deployProxy(Verifier);
        await verifier.deployed();
        await verifier.setAddressBook(addressbook.address);
        await verifier.updateSigner(owner.address);
        await addressbook.set("verifier", verifier.address);
        await presale.setTreasury(owner.address);
        await presale.setPaymentToken(payment.address);
        await presale.setVerifier(verifier.address);
    });
    it("Can purchase a presale NFT", async function () {
        await token.mint(owner.address, "270000000000000000000000");
        await token.approve(vault.address, "270000000000000000000000");
        await vault["deposit(uint256)"]("270000000000000000000000");
        await timeout(30000);
        await vault.airdrop(addr1.address, "10");
    });
});

async function getBlockTimestamp () {
    return (await hre.ethers.provider.getBlock("latest")).timestamp;
}

const getSalt = (max, price, value, total) => {
    return ['max', max, 'price', price, 'value', value, 'total', total].join('');
}

const getSignature = (pkey, address, salt, expiration) => {
    const encoder = hre.ethers.utils.defaultAbiCoder;
    let messageHash = hre.ethers.utils.sha256(encoder.encode(['address', 'string', 'uint256'], [address, salt, expiration]));
    return EthCrypto.sign(pkey, messageHash);
};

const timeout = (ms) => {
    return new Promise(resolve => setTimeout(resolve, ms));
}
