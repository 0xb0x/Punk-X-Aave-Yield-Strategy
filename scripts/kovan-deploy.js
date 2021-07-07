
const hre = require("hardhat");

async function main() {

  
  token = '0x6b175474e89094c44da98b954eedeac495271d0f' // mainnet DAI
  Lending_pool = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9'
  StkAave = '0x4da27a545c0c5b758a6ba100e3a049001de870f5'
  Aave_Token = '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9'
  Incentives_Controller = '0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5'
  UniswapV2Router02 = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D'

  const [forge] = await ethers.getSigners();

  // We get the contract to deploy
  const AaveModel = await hre.ethers.getContractFactory("KovanAaveModel");
  const aaveModel = await AaveModel.deploy();

  await aaveModel.deployed();

  console.log("Kovan Aave Model deployed to:", aaveModel.address);
  console.log("........initializing contract");
  await aaveModel.initialize(
    forge.address,
    Lending_pool,
    token,
    UniswapV2Router02,
  );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
