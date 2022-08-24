const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const EthCrypto = require("eth-crypto");
const { toBigNum, fromBigNum } = require("./utils.js");

var ERC20ABI = artifacts.readArtifactSync("contracts/FakeUsdc.sol:IERC20").abi;
var pairContract;

var exchangeRouter;
var exchangeFactory;
let wBNB;
let fakeUSDC;
let fakeUSDT;

let addressbook;
let claim;
let downline;
let pool;
let swap;
let token;
let vault;
let addLiquidity;
let lpStaking;

var owner;
var user1;
var user2;

var isOnchain = false; //true: bsc testnet, false: hardhat net

var deployedAddress = {
  exchangeFactory: "0xb7926c0430afb07aa7defde6da862ae0bde767bc",
  wBNB: "0xae13d989dac2f0debff460ac112a837c89baa7cd",
  exchangeRouter: "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",
  token: "0xbeEA1e568B75C78611b9af840b68DFF605F853a1",
  fakeUSDC: "0x7F8CE1b5486F24cd4e5CB98e78d306cD71Ea337b",
  fakeUSDT: "0x60c83C6D100C916069B230167c37358dC2997083",
  addressbook: "0x87521B640E2F7B1903a4be20032fd66CabC0EcCd",
  claim: "0x452629e243691CA6BDaf525783F75943FbbF67D0",
  downline: "0xc195f52841ad5cb92b14200eC4419465C30353C1",
  pool: "0x0a9CaCf02693F7cE024E75E59B23fBAc9ee11584",
  swap: "0x0ec88Da2d0a9de9D9D2c2B80F8b4EBa7F7A5b46A",
  vault: "0x92f087E7e2420f179b570E6719868a50078F941d",
  addLiquidity: "0xAcE453642cbE492ad874669ad313840f8Ab672cA",
  lpStaking: "0x48269452BD2F6c6882d3a5bce2C769DE977351a2",
};
///////////********* create account and contract deploy and set ********////////////////////

describe("Create Account and wallet", () => {
  it("Create Wallet", async () => {
    [owner, safe, user1, user2] = await ethers.getSigners();
    console.log("owner", owner.address);
    console.log("safe", safe.address);
    console.log("user1", user1.address);
    console.log("user2", user2.address);
  });
});

describe("Contracts deploy", () => {
  // ------ dex deployment ------- //
  it("Factory deploy", async () => {
    const Factory = await ethers.getContractFactory("PancakeFactory");
    if (!isOnchain) {
      exchangeFactory = await Factory.deploy(owner.address);
      await exchangeFactory.deployed();
      console.log(await exchangeFactory.INIT_CODE_PAIR_HASH());
    } else {
      exchangeFactory = Factory.attach(deployedAddress.exchangeFactory);
    }
    console.log("Factory", exchangeFactory.address);
  });

  it("WBNB deploy", async () => {
    const WBNB_ = await ethers.getContractFactory("WBNB");
    if (!isOnchain) {
      wBNB = await WBNB_.deploy();
      await wBNB.deployed();
    } else {
      wBNB = WBNB_.attach(deployedAddress.wBNB);
    }
    console.log("WBNB", wBNB.address);
  });

  it("Router deploy", async () => {
    const Router = await ethers.getContractFactory("PancakeRouter");
    if (!isOnchain) {
      exchangeRouter = await Router.deploy(
        exchangeFactory.address,
        wBNB.address
      );
      await exchangeRouter.deployed();
    } else {
      exchangeRouter = Router.attach(deployedAddress.exchangeRouter);
    }
    console.log("Router", exchangeRouter.address);
  });

  it("Token deploy", async () => {
    Token = await ethers.getContractFactory("Token");
    TokenV1 = await ethers.getContractFactory("TokenV1");

    if (!isOnchain) {
        token = await upgrades.deployProxy(Token);
        await token.deployed();
        token = await upgrades.upgradeProxy(token.address, TokenV1);
        await token.deployed();
    } else {
      token = Token.attach(deployedAddress.token);
    }
    console.log("token", token.address);
  });

  // ------ dex deployment ------- //
  it("FakeUSDC deploy", async () => {
    const FakeUSDC = await ethers.getContractFactory("FakeUsdc");
    if (!isOnchain) {
      fakeUSDC = await FakeUSDC.deploy();
      await fakeUSDC.deployed();
    } else {
      fakeUSDC = FakeUSDC.attach(deployedAddress.fakeUSDC);
    }
    console.log("fakeUSDC", fakeUSDC.address);
  });

  it("FakeUSDT deploy", async () => {
    const FakeUSDT = await ethers.getContractFactory("FakeUsdt");
    if (!isOnchain) {
      fakeUSDT = await FakeUSDT.deploy();
      await fakeUSDT.deployed();
    } else {
      fakeUSDT = FakeUSDT.attach(deployedAddress.fakeUSDT);
    }
    console.log("fakeUSDT", fakeUSDT.address);
  });

  it("AddressBook deploy", async () => {
    AddressBook = await ethers.getContractFactory("AddressBook");
    if (!isOnchain) {
      addressbook = await upgrades.deployProxy(AddressBook);
      await addressbook.deployed();

      var tx = await addressbook.set("safe", safe.address);
      await tx.wait();
      var tx = await addressbook.set("payment", fakeUSDC.address);
      await tx.wait();
      var tx = await addressbook.set("router", exchangeRouter.address);
      await tx.wait();
      var tx = await addressbook.set("factory", exchangeFactory.address);
      await tx.wait();
      var tx = await addressbook.set("lpLockReceiver", safe.address);
      await tx.wait();
    } else {
      addressbook = AddressBook.attach(deployedAddress.addressbook);
    }
    console.log("AddressBook", addressbook.address);
  });

  it("Claim deploy", async () => {
    Claim = await ethers.getContractFactory("Claim");
    if (!isOnchain) {
      claim = await upgrades.deployProxy(Claim);
      await claim.deployed();
      var tx = await claim.setAddressBook(addressbook.address);
      await tx.wait();
      var tx = await addressbook.set("claim", claim.address);
      await tx.wait();
    } else {
      claim = Claim.attach(deployedAddress.claim);
    }
    console.log("claim", claim.address);
  });

  it("Downline deploy", async () => {
    Downline = await ethers.getContractFactory("Downline");
    if (!isOnchain) {
      downline = await upgrades.deployProxy(Downline);
      await downline.deployed();
      var tx = await downline.setAddressBook(addressbook.address);
      await tx.wait();
      var tx = await addressbook.set("downline", downline.address);
      await tx.wait();
    } else {
      downline = Downline.attach(deployedAddress.downline);
    }
    console.log("downline", downline.address);
  });

  it("Pool deploy", async () => {
    Pool = await ethers.getContractFactory("Pool");
    if (!isOnchain) {
      pool = await upgrades.deployProxy(Pool);
      await pool.deployed();
      var tx = await pool.setAddressBook(addressbook.address);
      await tx.wait();
      var tx = await addressbook.set("pool", pool.address);
      await tx.wait();
    } else {
      pool = Pool.attach(deployedAddress.pool);
    }
    console.log("pool", pool.address);
  });

  it("Swap deploy and set", async () => {
    Swap = await ethers.getContractFactory("Swap");
    if (!isOnchain) {
      swap = await upgrades.deployProxy(Swap);
      await swap.deployed();
      var tx = await swap.setAddressBook(addressbook.address);
      await tx.wait();
      var tx = await addressbook.set("swap", swap.address);
      await tx.wait();
    } else {
      swap = Swap.attach(deployedAddress.swap);
    }
    console.log("swap", swap.address);
  });

  it("Token set", async () => {
    if (!isOnchain) {
      var tx = await token.setAddressBook(addressbook.address);
      await tx.wait();
      var tx = await addressbook.set("token", token.address);
      await tx.wait();
    } else {
    }
  });

  it("Vault deploy and set", async () => {
    Vault = await ethers.getContractFactory("Vault");
    if (!isOnchain) {
      vault = await upgrades.deployProxy(Vault);
      await vault.deployed();
      var tx = await vault.setAddressBook(addressbook.address);
      await tx.wait();
      var tx = await addressbook.set("vault", vault.address);
      await tx.wait();
    } else {
      vault = Vault.attach(deployedAddress.vault);
    }
    console.log("vault", vault.address);
  });

  it("AddLiquidity deploy and set", async () => {
    Addliquidity = await ethers.getContractFactory("AddLiquidity");
    if (!isOnchain) {
      addLiquidity = await upgrades.deployProxy(Addliquidity);
      await addLiquidity.deployed();
      var tx = await addLiquidity.setAddressBook(addressbook.address);
      await tx.wait();
      var tx = await addressbook.set("addLiquidity", addLiquidity.address);
      await tx.wait();
    } else {
      addLiquidity = Addliquidity.attach(deployedAddress.addLiquidity);
    }
    console.log("addLiquidity", addLiquidity.address);
  });

  it("LPStaking deploy and set", async () => {
    LPStaking = await ethers.getContractFactory("LPStaking");
    LPStakingV1 = await ethers.getContractFactory("LPStakingV1");

    if (!isOnchain) {
      lpStaking = await upgrades.deployProxy(LPStaking);
      await lpStaking.deployed();
      lpStaking = await upgrades.upgradeProxy(lpStaking.address, LPStakingV1);
      await lpStaking.deployed();
      var tx = await lpStaking.setAddressBook(addressbook.address);
      await tx.wait();
      var tx = await addressbook.set("lpStaking", lpStaking.address);
      await tx.wait();

      // var tx = await addressbook.set("lpLockReceiver", lpLockReceiver.address);
      // await tx.wait();

      /************* set path **************/
      await lpStaking.setSwapPathFromTokenToUSDC(fakeUSDT.address, [
        fakeUSDT.address,
        fakeUSDC.address,
      ]);
    } else {
      lpStaking = LPStaking.attach(deployedAddress.lpStaking);
    }
    console.log("lpStaking", lpStaking.address);
  });
});

//*********************************** create pool and send some cryto to accounts **************************************************//
describe("test prepare ", () => {
  it("creat USDC-FUR pool", async () => {
    if (!isOnchain) {
      var tx = await fakeUSDC.transfer(pool.address, toBigNum("1111368", 18));
      await tx.wait();

      var tx = await pool.createLiquidity();
      await tx.wait();
    } else {
    }
    var pair = await exchangeFactory.getPair(fakeUSDC.address, token.address);
    pairContract = new ethers.Contract(pair, ERC20ABI, owner);
    console.log("pair", pairContract.address);
  });

  it("creat USDC-USDT pool", async () => {
    if (!isOnchain) {
      var tx = await fakeUSDT.approve(
        exchangeRouter.address,
        toBigNum("100000", 6)
      );
      await tx.wait();

      var tx = await fakeUSDC.approve(
        exchangeRouter.address,
        toBigNum("100000", 18)
      );
      await tx.wait();

      var tx = await exchangeRouter.addLiquidity(
        fakeUSDC.address,
        fakeUSDT.address,
        toBigNum("100000", 18),
        toBigNum("100000", 6),
        0,
        0,
        owner.address,
        "1234325432314321"
      );
      await tx.wait();
    } else {
    }
  });


  it("create USDC-BNB pool", async () => {
    if (!isOnchain) {
      var tx = await fakeUSDC.approve(
        exchangeRouter.address,
        toBigNum("10000", 18)
      );
      await tx.wait();

      var tx = await exchangeRouter.addLiquidityETH(
        fakeUSDC.address,
        toBigNum("10000", 18),
        0,
        0,
        owner.address,
        "1234325432314321",
        { value: ethers.utils.parseUnits("0.5", 18) }
      );
      await tx.wait();
    }
  });

});



describe("test", () => {

  it("user1 stake LP with USDC", async () => {
    if (!isOnchain) {
      //transfer
      var tx = await fakeUSDC.transfer(
        user1.address,
        ethers.utils.parseUnits("1000", 18)
      );
      await tx.wait();

        //approve
      var tx = await fakeUSDC
        .connect(user1)
        .approve(lpStaking.address, fakeUSDC.balanceOf(user1.address));
      await tx.wait();

        //stake
      var tx = await lpStaking
        .connect(user1)
        .stake(fakeUSDC.address, fakeUSDC.balanceOf(user1.address), 0);
      await tx.wait();
    }
  });


  it("user1 stake LP with USDT", async () => {
    if (!isOnchain) {
      //transfer
      var tx = await fakeUSDT.transfer(user1.address, toBigNum("11113", 6));
      await tx.wait();

      //approve
      var tx = await fakeUSDT
        .connect(user1)
        .approve(lpStaking.address, fakeUSDT.balanceOf(user1.address));
      await tx.wait();

      //stake
      var tx = await lpStaking
      .connect(user1)
      .stake(fakeUSDT.address, fakeUSDT.balanceOf(user1.address), 0);
    await tx.wait();
    }
  });

  it("owner stake LP with BNB for a month", async () => {
    if (!isOnchain) {
      //stake
      var tx = await lpStaking
      .stakeWithEth(ethers.utils.parseUnits("0.1", 18),
       1,
      {value: ethers.utils.parseUnits("0.1", 18)}
      );      
      await tx.wait();
    }
  });

  it("owner stake LP with Fur for a month", async () => {
    if (!isOnchain) {
      //mint
      var tx = await token.mint(owner.address, toBigNum("100", 18));
      await tx.wait();

      //approve
      var tx = await token
        .approve(lpStaking.address, toBigNum("100", 18));
      await tx.wait();

      //stake
      var tx = await lpStaking
          .stake(token.address, toBigNum("100", 18), 1);
      await tx.wait();
    }
  });

  it("owner stake LP with Fur for two month ", async () => {
    if (!isOnchain) {
      //mint
      var tx = await token.mint(owner.address, toBigNum("100", 18));
      await tx.wait();

      //approve
      var tx = await token
        .approve(lpStaking.address, toBigNum("100", 18));
      await tx.wait();

      //stake
      var tx = await lpStaking
          .stake(token.address, toBigNum("100", 18), 2);
      await tx.wait();
    }
  });

  it("owner unstake LP", async () => {
    if (!isOnchain) {
      await network.provider.send("evm_increaseTime", [86400 * 60]);
      await network.provider.send("evm_mine");

      var tx = await lpStaking.unstake();
      await tx.wait();
    }
  });
});
