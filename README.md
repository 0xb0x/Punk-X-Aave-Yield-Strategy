# Punk-X-Aave-Yield-Strategy
Strategy to earn yield on [punk.finance](https://punk.finance) protocol utilizing the aave protocol

## Strategy

This strategy chases the highest deposit apy on tokens in the aave lending pool. 
To add a token to be used by this strategy call `_addToken()`. 
When depositing into the lending pool it checks which token currently has the highest deposit apy and apes into it. While implementing this strategy we can also claim staked aave tokens `stkAave` on eth mainnet as reward for depositing incentiviced tokens into the lending pool. `stkAave` has a lock - (cooldown period) before it can be redeemed for aave token. This strategy also claims the staked aave token and swaps it to the underlying. :notes: *put it on repeat aan aan*

## Setup

- Install dependencies - `npm i`

- Create `.env` in root directory

- Add env variables 
```
MNEMONIC=
ALCHEMY_API_KEY=

```

## Deployment

Currently afaik the aave incentives contract isn't deployed on the kovan network.
A modified version of `AaveModel.sol` which doesn't implement `IAaveIncentivesController.sol` has being created for deployment to the kovan network.

```
# To deploy to kovan network
run - npx hardhat run --network kovan scripts/kovan-deploy.js

# To deploy `AaveModel.sol` to forked mainnet.
run - npx hardhat run --network hardhat scripts/deploy.js

```

### Kovan Contracts
Lending Pool - `0xE0fBa4Fc209b4948668006B2bE61711b7f`

UniswapV2Router02 - `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`

### Mainnet Contracts

Lending pool - `0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9`

Staked Aave Token - `0x4da27a545c0c5b758a6ba100e3a049001de870f5`

Aave Token - `0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9`

Incentives Controller - `0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5`

UniswapV2Router02 - `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`


## Note
This strategy is most suitable for stablecoins to prevent excess loss due to slippage.

Deployed Aave contract addresses can be found here - [Aave-Contracts](https://docs.aave.com/developers/deployed-contracts/deployed-contracts)

## Todo

