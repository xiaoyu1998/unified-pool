## Unified Pool Contracts

Download

```shell
git clone git@github.com:xiaoyu1998/up-contracts.git --recursive
```
Installation

```shell
npm install
```
Run local node
```shell
npx hardhat node
```
Deploy contracts
```shell
npx hardhat ignition deploy ignition/modules/deployExchangeRouter.ts --network localhost
```
Execute contract terms
```shell
npx hardhat run scripts/0createUsdtUniV3.ts --network localhost
npx hardhat run scripts/1createPools.ts --network localhost
npx hardhat run scripts/2oracleKeeper.ts --network localhost
npx hardhat run scripts/3executeSupply.ts --network localhost
npx hardhat run scripts/4executeWithdraw.ts --network localhost
npx hardhat run scripts/5executeDeposit.ts --network localhost
npx hardhat run scripts/6executeBorrow.ts --network localhost
npx hardhat run scripts/7executeRepay.ts --network localhost
npx hardhat run scripts/8executeRedeem.ts --network localhost
npx hardhat run scripts/9executeSwap.ts --network localhost
```