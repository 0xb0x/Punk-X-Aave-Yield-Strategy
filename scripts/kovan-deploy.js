
const hre = require("hardhat");

async function main() {

  // We get the contract to deploy
  const AaveModel = await hre.ethers.getContractFactory("KovanAaveModel");
  const aaveModel = await AaveModel.deploy();

  await aaveModel.deployed();

  console.log("Kovan Aave Model deployed to:", aaveModel.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
