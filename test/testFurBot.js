const { expect } = require("chai");
const Contract = require("../scripts/utils/Contract");


describe("Furbet", function () {
    let tx;

    // RUN THIS BEFORE EACH TEST
    beforeEach(async function () {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        let contract = new Contract();
        // Deploy AddressBook
        addressbook = await contract.deploy("AddressBook");
        // Re instantiate contract with new addressbook
        contract = new Contract(addressbook.address);
        // Deploy USDC
        usdc = await contract.deploy("FakeToken", "payment", ["USD Coin", "USDC"]);
        // Deploy vault
        vault = await contract.deploy("Vault", "vault");
        // Deploy FurBot
        furbot = await contract.deploy("FurBot", "furbot");
        // Setup FurBot
        tx = await furbot.setup();
        await tx.wait();
    });

    describe("Deployment", function () {
        it("Has the right name", async function () {
            expect(await furbot.name()).to.equal("FurBot");
        });
        it("Has the right symbol", async function () {
            expect(await furbot.symbol()).to.equal("$FURBOT");
        });
        it("Has the right total supply", async function () {
            expect(await furbot.totalSupply()).to.equal(0);
        });
        it("Has the right total investment", async function () {
            expect(await furbot.totalInvestment()).to.equal(0);
        });
        it("Has the right total dividends", async function () {
            expect(await furbot.totalDividends()).to.equal(0);
        });
    });

    describe("Admin", function () {
        it("Can create a generation", async function () {
            expect(await furbot.createGeneration(5000, "https://example.com/image.jpg")).to.emit(furbot, "GenerationCreated").withArgs(1);
        });
        it("Cannot create a generation from non admin user", async function () {
            await expect(furbot.connect(addr1).createGeneration(5000, "https://example.com/image.jpg")).to.be.revertedWith("Ownable: caller is not the owner");
        });
        it("Can create a sale", async function () {
            timestamp = await getBlockTimestamp();
            expect(await furbot.createGeneration(5000, "https://example.com/image.jpg")).to.emit(furbot, "GenerationCreated").withArgs(1);
            expect(await furbot.createSale(1, 200, timestamp + 200, timestamp + 400, false)).to.emit(furbot, "SaleCreated").withArgs(1);
        });
        it("Cannot create a sale from non admin user", async function () {
            timestamp = await getBlockTimestamp();
            expect(await furbot.createGeneration(5000, "https://example.com/image.jpg")).to.emit(furbot, "GenerationCreated").withArgs(1);
            await expect(furbot.connect(addr1).createSale(1, 200, timestamp + 200, timestamp + 400, false)).to.be.revertedWith("Ownable: caller is not the owner");
        });
    });

});

async function getBlockTimestamp () {
    return (await hre.ethers.provider.getBlock("latest")).timestamp;
}
