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
npx hardhat run scripts/0createUsdtUni.ts --network localhost
npx hardhat run scripts/1createPools.ts --network localhost
npx hardhat run scripts/2executeSupply.ts --network localhost
npx hardhat run scripts/3executeWithdraw.ts --network localhost
npx hardhat run scripts/4executeDeposit.ts --network localhost
npx hardhat run scripts/5oracleKeeper.ts --network localhost
npx hardhat run scripts/6executeBorrow.ts --network localhost
npx hardhat run scripts/7executeRepay.ts --network localhost
npx hardhat run scripts/8executeRedeem.ts --network localhost
```