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
Deplopy contracts
```shell
npx hardhat ignition deploy ignition/modules/deployExchangeRouter.ts --network localhost
```
Execute contract terms
```shell
npx hardhat run scripts/1createUsdtUni.ts --network localhost
npx hardhat run scripts/2createPools.ts --network localhost
npx hardhat run scripts/3executeSupply.ts --network localhost
npx hardhat run scripts/4executeWithdraw.ts --network localhost
```