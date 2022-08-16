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
let presale;
let swap;
let token;
let tokenV1;
let vault;
let verifier;
let addLiquidity;
let lpStaking;
let lpSwap;

var owner;
var safe;
var user1;
var user2;
var lpLockReceiver;

describe("Create Account and wallet", () => {
  it("Create Wallet", async () => {
    [owner, safe, user1, user2, user3] = await ethers.getSigners();

    lpLockReceiver = ethers.Wallet.createRandom();
    lpLockReceiver = lpLockReceiver.connect(ethers.provider);
  });
});

describe("Contracts deploy", () => {
  // ------ dex deployment ------- //
  it("Factory deploy", async () => {
    const Factory = await ethers.getContractFactory("PancakeFactory");
    exchangeFactory = await Factory.deploy(owner.address);
    await exchangeFactory.deployed();
    console.log(await exchangeFactory.INIT_CODE_PAIR_HASH());
  });

  it("WBNB deploy", async () => {
    const WBNB_ = await ethers.getContractFactory("WBNB");
    wBNB = await WBNB_.deploy();
    await wBNB.deployed();
  });

  it("Router deploy", async () => {
    const Router = await ethers.getContractFactory("PancakeRouter");
    exchangeRouter = await Router.deploy(exchangeFactory.address, wBNB.address);
    await exchangeRouter.deployed();
  });

  // ------ dex deployment ------- //
  it("FakeUSDC deploy", async () => {
    const FakeUSDC = await ethers.getContractFactory("FakeUsdc");
    fakeUSDC = await FakeUSDC.deploy();
    await fakeUSDC.deployed();
  });

  it("FakeUSDT deploy", async () => {
    const FakeUSDT = await ethers.getContractFactory("FakeUsdt");
    fakeUSDT = await FakeUSDT.deploy();
    await fakeUSDT.deployed();
  });

  it("AddressBook deploy", async () => {
    AddressBook = await ethers.getContractFactory("AddressBook");
    addressbook = await upgrades.deployProxy(AddressBook);
    await addressbook.deployed();

    await addressbook.set("safe", safe.address);
    await addressbook.set("payment", fakeUSDC.address);
    await addressbook.set("router", exchangeRouter.address);
    await addressbook.set("factory", exchangeFactory.address);
  });

  it("Claim deploy", async () => {
    Claim = await ethers.getContractFactory("Claim");
    claim = await upgrades.deployProxy(Claim);
    await claim.deployed();
    await claim.setAddressBook(addressbook.address);
    await addressbook.set("claim", claim.address);
  });

  it("Downline deploy", async () => {
    Downline = await ethers.getContractFactory("Downline");
    downline = await upgrades.deployProxy(Downline);
    await downline.deployed();
    await downline.setAddressBook(addressbook.address);
    await addressbook.set("downline", downline.address);
  });

  it("Pool deploy", async () => {
    Pool = await ethers.getContractFactory("Pool");
    pool = await upgrades.deployProxy(Pool);
    await pool.deployed();
    await pool.setAddressBook(addressbook.address);
    await addressbook.set("pool", pool.address);

    // console.log(pool.address," pool/proxy");
  });

  it("Swap deploy and set", async () => {
    Swap = await ethers.getContractFactory("Swap");
    swap = await upgrades.deployProxy(Swap);
    await swap.deployed();
    await swap.setAddressBook(addressbook.address);
    await addressbook.set("swap", swap.address);
  });

  it("Token deploy and set", async () => {
    Token = await ethers.getContractFactory("Token");
    TokenV1 = await ethers.getContractFactory("TokenV1");

    token = await upgrades.deployProxy(Token);
    // console.log(token.address," token/proxy")
    // console.log(await upgrades.erc1967.getImplementationAddress(token.address)," getImplementationAddress")
    // console.log(await upgrades.erc1967.getAdminAddress(token.address), " getAdminAddress")
    tokenV1 = await upgrades.upgradeProxy(token.address, TokenV1);
    // console.log(TokenV1.address," tokenV1/proxy after upgrade")
    // console.log(await upgrades.erc1967.getImplementationAddress(tokenV1.address)," getImplementationAddress after upgrade")
    // console.log(await upgrades.erc1967.getAdminAddress(tokenV1.address)," getAdminAddress after upgrade")
    await tokenV1.setAddressBook(addressbook.address);
    await addressbook.set("token", tokenV1.address);
  });

  it("Vault deploy and set", async () => {
    Vault = await ethers.getContractFactory("Vault");
    vault = await upgrades.deployProxy(Vault);
    await vault.deployed();
    await vault.setAddressBook(addressbook.address);
    await addressbook.set("vault", vault.address);
  });

  it("Verifier deploy and set", async () => {
    Verifier = await ethers.getContractFactory("Verifier");
    verifier = await upgrades.deployProxy(Verifier);
    await verifier.deployed();
    await verifier.setAddressBook(addressbook.address);
    await verifier.updateSigner(owner.address);
    await addressbook.set("verifier", verifier.address);
  });

  it("Presale deploy and set", async () => {
    Presale = await ethers.getContractFactory("Presale");
    presale = await Presale.deploy();
    await addressbook.set("presale", presale.address);

    await presale.setTreasury(owner.address);
    await presale.setPaymentToken(fakeUSDC.address);
    await presale.setVerifier(verifier.address);
  });

  it("AddLiquidity deploy and set", async () => {
    Addliquidity = await ethers.getContractFactory("AddLiquidity");
    addLiquidity = await upgrades.deployProxy(Addliquidity);
    await addLiquidity.deployed();
    await addLiquidity.setAddressBook(addressbook.address);
    await addressbook.set("addLiquidity", addLiquidity.address);
  });

  it("LPStaking deploy and set", async () => {
    LPStaking = await ethers.getContractFactory("LPStaking");
    lpStaking = await upgrades.deployProxy(LPStaking);
    await lpStaking.deployed();
    await lpStaking.setAddressBook(addressbook.address);
    await addressbook.set("lpRewardPool", lpStaking.address);
    await addressbook.set("lpLockReceiver", lpLockReceiver.address);
  });

  it("LPSwap deploy and set", async () => {
    LPSwap = await ethers.getContractFactory("LPSwap");
    lpSwap = await upgrades.deployProxy(LPSwap);
    await lpSwap.deployed();
    await lpSwap.setAddressBook(addressbook.address);
    ///////////////////////////////////////////////////////////////////////////////
    await lpSwap.setSwapPathFromTokenToUSDC(wBNB.address, [
      wBNB.address,
      fakeUSDC.address,
    ]);
    await lpSwap.setSwapPathFromTokenToUSDC(fakeUSDT.address, [
      fakeUSDT.address,
      fakeUSDC.address,
    ]);
  });
});

describe("test ", () => {
  it("creat USDC-FUR pool", async () => {
    var tx = await fakeUSDC.transfer(pool.address, toBigNum("200000000000", 6));
    await tx.wait();

    var tx = await pool.createLiquidity();
    await tx.wait();

    var pair = await exchangeFactory.getPair(fakeUSDC.address, tokenV1.address);
    pairContract = new ethers.Contract(pair, ERC20ABI, owner);

    var provider = ethers.provider;
    console.log(
      "owner WBNB balance",
      fromBigNum(await provider.getBalance(owner.address), 18)
    );
    console.log(
      "owner LP balance",
      fromBigNum(await pairContract.balanceOf(owner.address), 18)
    );
    console.log(
      "safe LP balance",
      fromBigNum(await pairContract.balanceOf(safe.address), 18)
    );
    console.log(
      "lpLockReceiver LP balance",
      fromBigNum(await pairContract.balanceOf(lpLockReceiver.address), 18)
    );
  });

  it("send LP tokens to user1, user2", async () => {
    var tx = await pairContract
      .connect(safe)
      .transfer(user1.address, toBigNum("0.00004", 18));
    await tx.wait();
    var tx = await pairContract
      .connect(safe)
      .transfer(user2.address, toBigNum("0.00005", 18));
    await tx.wait();
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("send USDC to user1, user2, user3", async () => {
    var tx = await fakeUSDC.transfer(user1.address, toBigNum("1000", 6));
    await tx.wait();
    var tx = await fakeUSDC.transfer(user2.address, toBigNum("2000", 6));
    await tx.wait();
    var tx = await fakeUSDC.transfer(user3.address, toBigNum("3000", 6));
    await tx.wait();
  });

  it("check USDC balance", async () => {
    await checkUSDCBalance();
  });

  it("approve user3 USDC", async () => {
    var tx = await fakeUSDC
      .connect(user3)
      .approve(lpSwap.address, fakeUSDC.balanceOf(user3.address));
    await tx.wait();
  });
 //********************************************user3 buy LP using USDC********************************************* */
  it("user3 buy LP using USDC", async () => {
    var tx = await lpSwap
      .connect(user3)
      .buyLP(fakeUSDC.address, fakeUSDC.balanceOf(user3.address));
    await tx.wait();
  });

  it("check USDC balance", async () => {
    await checkUSDCBalance();
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("set LP holders address for LP reflection", async () => {
    var tx = await lpStaking.connect(safe).registerAddress();
    await tx.wait();

    var tx = await lpStaking.connect(user1).registerAddress();
    await tx.wait();

    var tx = await lpStaking.connect(user2).registerAddress();
    await tx.wait();

    var tx = await lpStaking.connect(user3).registerAddress();
    await tx.wait();
  });

  it("safe LP approve", async () => {
    var tx = await pairContract
      .connect(safe)
      .approve(lpStaking.address, pairContract.balanceOf(safe.address));
    await tx.wait();
  });

  it("safe holded LP stake", async () => {
    var tx = await lpStaking
      .connect(safe)
      .stake(pairContract.balanceOf(safe.address), 0);
    await tx.wait();
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("user1 LP approve", async () => {
    var tx = await pairContract
      .connect(user1)
      .approve(lpStaking.address, pairContract.balanceOf(user1.address));
    await tx.wait();
  });

  it("user1 holded LP stake", async () => {
    await network.provider.send("evm_increaseTime", [86400]);
    await network.provider.send("evm_mine");

    var tx = await lpStaking
      .connect(user1)
      .stake(pairContract.balanceOf(user1.address), 0);
    await tx.wait();
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("user2 LP approve", async () => {
    var tx = await pairContract
      .connect(user2)
      .approve(lpStaking.address, pairContract.balanceOf(user2.address));
    await tx.wait();
  });

  it("user2 holded LP stake for a month", async () => {
    var tx = await lpStaking
      .connect(user2)
      .stake(pairContract.balanceOf(user2.address), 1);
    await tx.wait();

    await network.provider.send("evm_increaseTime", [86400]);
    await network.provider.send("evm_mine");
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("check  pending rewards", async () => {
    await checkPendingRewards();
  });

  it("safe LP Reward claim", async () => {
    var tx = await lpStaking.connect(safe).claimRewards();
    await tx.wait();
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("check  pending rewards", async () => {
    await checkPendingRewards();
  });

  it("user1 LP Reward claim", async () => {
    var tx = await lpStaking.connect(user1).claimRewards();
    await tx.wait();

    await network.provider.send("evm_increaseTime", [86400]);
    await network.provider.send("evm_mine");
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("check  pending rewards", async () => {
    await checkPendingRewards();
  });

  it("check staking LP balance", async () => {
    await checkStakingBalance();
  });
//******************************************** user2 LP Reward compound ************************************************* */
  it("user2 LP Reward compound", async () => {
    await network.provider.send("evm_increaseTime", [86400]);
    await network.provider.send("evm_mine");

    var tx = await lpStaking.connect(user2).compound();
    await tx.wait();
  });

  it("check staking LP balance", async () => {
    await checkStakingBalance();
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("check  pending rewards", async () => {
    await checkPendingRewards();
  });

  it("user1 LP unstake", async () => {
    var tx = await lpStaking.connect(user1).unstake();
    await tx.wait();

    await network.provider.send("evm_increaseTime", [86400]);
    await network.provider.send("evm_mine");
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("user2 LP unstake", async () => {
    await network.provider.send("evm_increaseTime", [2592000]);
    await network.provider.send("evm_mine");

    var tx = await lpStaking.connect(user2).unstake();
    await tx.wait();
  });

  it("safe LP unstake", async () => {
    await network.provider.send("evm_increaseTime", [2592000]);
    await network.provider.send("evm_mine");

    var tx = await lpStaking.connect(safe).unstake();
    await tx.wait();
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("user2 approve LP", async () => {
    var tx = await pairContract
      .connect(user2)
      .approve(lpSwap.address, pairContract.balanceOf(user2.address));
    await tx.wait();
  });
/********************************************** user2 sell LP with USDC ***************************************************** */
  it("user2 sell LP with USDC", async () => {
    var tx = await lpSwap
      .connect(user2)
      .sellLP(pairContract.balanceOf(user2.address));
    await tx.wait();
  });

  it("check all users LP balance", async () => {
    await checkLPBalance();
  });

  it("check USDC balance", async () => {
    await checkUSDCBalance();
  });
});
//////////////////////////////////////////////////////buy LP test with USDT/////////////////////////////////////////////////////
describe("buy LP test with USDT", () => {
  it("approve USDT", async () => {
    var tx = await fakeUSDT.approve(
      exchangeRouter.address,
      toBigNum("100000", 6)
    );
    await tx.wait();
  });

  it("approve USDC", async () => {
    var tx = await fakeUSDC.approve(
      exchangeRouter.address,
      toBigNum("100000", 6)
    );
    await tx.wait();
  });

  it("creat USDC-USDT pool", async () => {
    var tx = await exchangeRouter.addLiquidity(
      fakeUSDC.address,
      fakeUSDT.address,
      toBigNum("100000", 6),
      toBigNum("100000", 6),
      0,
      0,
      owner.address,
      "1234325432314321"
    );
    await tx.wait();
    console.log(
      "owner USDT balance",
      fromBigNum(await fakeUSDT.balanceOf(owner.address), 6)
    );
    console.log(
      "owner USDC balance",
      fromBigNum(await fakeUSDC.balanceOf(owner.address), 6)
    );
    console.log(
      "owner token balance",
      fromBigNum(await tokenV1.balanceOf(owner.address), 18)
    );
    console.log(
      "owner LP balance",
      fromBigNum(await pairContract.balanceOf(owner.address), 18)
    );
  });

  it("approve owner USDT", async () => {
    var tx = await fakeUSDT.approve(lpSwap.address, toBigNum("1000", 6));
    await tx.wait();

    await network.provider.send("evm_increaseTime", [86400]);
    await network.provider.send("evm_mine");
  });

  it("owner buy LP using USDT", async () => {
    var tx = await lpSwap.buyLP(fakeUSDT.address, toBigNum("1000", 6));
    await tx.wait();

    console.log(
      "owner USDT balance",
      fromBigNum(await fakeUSDT.balanceOf(owner.address), 6)
    );
    console.log(
      "owner USDC balance",
      fromBigNum(await fakeUSDC.balanceOf(owner.address), 6)
    );
    console.log(
      "owner token balance",
      fromBigNum(await tokenV1.balanceOf(owner.address), 18)
    );
    console.log(
      "owner LP balance",
      fromBigNum(await pairContract.balanceOf(owner.address), 18)
    );
  });
});
////////////////////////////////////////////////// buy LP test with wBNB ////////////////////////////////////////////////////////
describe("buy LP test with wBNB", () => {
  it("approve USDC", async () => {
    var tx = await fakeUSDC.approve(
      exchangeRouter.address,
      toBigNum("10000", 6)
    );
    await tx.wait();

    await network.provider.send("evm_increaseTime", [86400]);
    await network.provider.send("evm_mine");
  });

  it("add liquidity eth", async () => {
    var tx = await exchangeRouter.addLiquidityETH(
      fakeUSDC.address,
      toBigNum("10000", 6),
      0,
      0,
      owner.address,
      "1234325432314321",
      { value: ethers.utils.parseUnits("100", 18) }
    );
    await tx.wait();
    var provider = ethers.provider;
    console.log(
      "owner WBNB balance",
      fromBigNum(await provider.getBalance(owner.address), 18)
    );
    console.log(
      "owner USDC balance",
      fromBigNum(await fakeUSDC.balanceOf(owner.address), 6)
    );
    console.log(
      "owner token balance",
      fromBigNum(await tokenV1.balanceOf(owner.address), 18)
    );
    console.log(
      "owner LP balance",
      fromBigNum(await pairContract.balanceOf(owner.address), 18)
    );
  });

  it("owner buy LP using wBNB", async () => {
    await network.provider.send("evm_increaseTime", [86400]);
    await network.provider.send("evm_mine");

    var tx = await lpSwap.buyLP(
      wBNB.address,
      ethers.utils.parseUnits("10", 18),
      { value: ethers.utils.parseUnits("10", 18) }
    );
    await tx.wait();

    console.log(
      "owner WBNB balance",
      fromBigNum(await ethers.provider.getBalance(owner.address), 18)
    );
    console.log(
      "owner USDC balance",
      fromBigNum(await fakeUSDC.balanceOf(owner.address), 6)
    );
    console.log(
      "owner token balance",
      fromBigNum(await tokenV1.balanceOf(owner.address), 18)
    );
    console.log(
      "owner LP balance",
      fromBigNum(await pairContract.balanceOf(owner.address), 18)
    );
  });
});

const checkLPBalance = async () => {
  console.log(
    "safe LP balance",
    fromBigNum(await pairContract.balanceOf(safe.address), 18)
  );
  console.log(
    "user1 LP balance",
    fromBigNum(await pairContract.balanceOf(user1.address), 18)
  );
  console.log(
    "user2 LP balance",
    fromBigNum(await pairContract.balanceOf(user2.address), 18)
  );
  console.log(
    "user3 LP balance",
    fromBigNum(await pairContract.balanceOf(user3.address), 18)
  );
  console.log(
    "lpLockReceiver LP balance",
    fromBigNum(await pairContract.balanceOf(lpLockReceiver.address), 18)
  );
};

const checkUSDCBalance = async () => {
  console.log(
    "user1 USDC balance",
    fromBigNum(await fakeUSDC.balanceOf(user1.address), 6)
  );
  console.log(
    "user2 USDC balance",
    fromBigNum(await fakeUSDC.balanceOf(user2.address), 6)
  );
  console.log(
    "user3 USDC balance",
    fromBigNum(await fakeUSDC.balanceOf(user3.address), 6)
  );
};

const checkPendingRewards = async () => {
  console.log(
    "safe pending reward",
    fromBigNum(await lpStaking.pendingReward(safe.address))
  );
  console.log(
    "user1 pending reward",
    fromBigNum(await lpStaking.pendingReward(user1.address))
  );
  console.log(
    "user2 pending reward",
    fromBigNum(await lpStaking.pendingReward(user2.address))
  );
};
const checkStakingBalance = async () => {
  console.log(
    "contract LP balance",
    fromBigNum(await pairContract.balanceOf(lpStaking.address), 18)
  );
  console.log(
    "totalStaking amount",
    fromBigNum(await lpStaking.totalStakingAmount(), 18)
  );
  let user2StakingData = await lpStaking.stakers(user2.address);
  console.log(
    "user2 Staking amount",
    fromBigNum(user2StakingData.stakingAmount, 18)
  );
};
