
const hre = require("hardhat");

async function main() {
  const OmniaStaking = await hre.ethers.getContractFactory("OmniaStaking");
  const omniaStaking = await OmniaStaking.deploy();
  await omniaStaking.deployed();
  console.log(`omniaStaking is deployed to ${omniaStaking.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
