import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";
import { Factory, Router, Pair, TestERC20 } from "../typechain-types";

describe("DEX", function () {
  let factory: Factory;
  let router: Router;
  let tokenA: TestERC20;
  let tokenB: TestERC20;
  let deployer: Signer;
  let user: Signer;

  beforeEach(async function () {
    [deployer, user] = await ethers.getSigners();

    // Deploy Factory
    const FactoryContract = await ethers.getContractFactory("Factory");
    factory = (await FactoryContract.deploy(
      await deployer.getAddress()
    )) as Factory;
    await factory.waitForDeployment();

    // Deploy Router
    const RouterContract = await ethers.getContractFactory("Router");
    router = (await RouterContract.deploy(
      await factory.getAddress()
    )) as Router;
    await router.waitForDeployment();

    // Deploy tokens
    const ERC20 = await ethers.getContractFactory("TestERC20");
    tokenA = (await ERC20.deploy("TokenA", "TKA", 18)) as TestERC20;
    tokenB = (await ERC20.deploy("TokenB", "TKB", 18)) as TestERC20;

    await tokenA.waitForDeployment();
    await tokenB.waitForDeployment();
  });

  it("should deploy all contracts correctly", async () => {
    const factoryAddress = await factory.getAddress();
    const routerAddress = await router.getAddress();
    const tokenAAddress = await tokenA.getAddress();
    const tokenBAddress = await tokenB.getAddress();

    expect(factoryAddress).to.properAddress;
    expect(routerAddress).to.properAddress;
    expect(tokenAAddress).to.properAddress;
    expect(tokenBAddress).to.properAddress;

    expect(await ethers.provider.getCode(factoryAddress)).to.not.equal("0x");
    expect(await ethers.provider.getCode(routerAddress)).to.not.equal("0x");
    expect(await ethers.provider.getCode(tokenAAddress)).to.not.equal("0x");
    expect(await ethers.provider.getCode(tokenBAddress)).to.not.equal("0x");
  });

  it("should create a new pair using deployed Router and Factory", async function () {
    const tokenAAddress = await tokenA.getAddress();
    const tokenBAddress = await tokenB.getAddress();

    // Ensure valid bytecode exists at token addresses
    expect(await ethers.provider.getCode(tokenAAddress)).to.not.equal("0x");
    expect(await ethers.provider.getCode(tokenBAddress)).to.not.equal("0x");

    // Create pair
    const tx = await factory.createPair(tokenAAddress, tokenBAddress);
    await tx.wait();

    // Get pair address
    const pairAddress = await factory.getPair(tokenAAddress, tokenBAddress);
    expect(pairAddress).to.not.equal(ethers.ZeroAddress);
    expect(await ethers.provider.getCode(pairAddress)).to.not.equal("0x");

    // Attach Pair contract
    const PairContract = await ethers.getContractFactory("Pair");
    const pair = PairContract.attach(pairAddress) as Pair;

    // Validate token0 and token1
    const token0 = await pair.token0();
    const token1 = await pair.token1();

    expect([token0, token1]).to.include(tokenAAddress);
    expect([token0, token1]).to.include(tokenBAddress);
  });
});
