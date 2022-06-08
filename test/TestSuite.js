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
        await payment.mint(owner.address, "250000000000000000000");
        const expiration = await getBlockTimestamp() + 600;
        const salt = getSalt("1", "250", "500", "300");
        const signature = getSignature(ownerPrivateKey, owner.address, salt, expiration);
        await payment.approve(presale.address, "250000000000000000000");
        await presale.buy(signature, "1", "1", "250", "500", "300", expiration);
        await claim.claim(100, owner.address, false);
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
