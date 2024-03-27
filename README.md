## Unified Pool Contracts

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
Create and print pools
```shell
npx hardhat run scripts/2createPools.ts --network localhost
npx hardhat run scripts/3printPools.ts --network localhost
```