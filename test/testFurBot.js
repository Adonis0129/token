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
    });

});
