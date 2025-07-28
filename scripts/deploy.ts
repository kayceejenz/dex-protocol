import { ethers } from "hardhat";

import { Factory__factory, Router__factory } from "../typechain-types";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("🚀 Deploying contracts with:", deployer.address);

  // Deploy Factory
  const factory = await new Factory__factory(deployer).deploy(deployer.address);
  await factory.waitForDeployment();
  const factoryAddress = await factory.getAddress();
  console.log("✅ Factory deployed to:", factoryAddress);

  // Deploy Router with Factory address
  const router = await new Router__factory(deployer).deploy(factoryAddress);
  await router.waitForDeployment();
  const routerAddress = await router.getAddress();
  console.log("✅ Router deployed to:", routerAddress);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
