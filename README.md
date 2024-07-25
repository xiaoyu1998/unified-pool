## Unified Pool Contracts

#### Download

```shell
git clone git@github.com:xiaoyu1998/up-contracts.git --recursive
```
#### Foundry support

```shell
curl -L https://foundry.paradigm.xyz | bash
```
#### Installation

```shell
npm install
```
#### Add Foundry Path
```shell
export PATH="$PATH:/from/path/.foundry/bin"
```
#### Run local node
```shell
npx hardhat node
```

#### Deploy contracts
```shell
npx hardhat ignition deploy ignition/modules/deployExchangeRouter.ts --network localhost
```
#### Init Supply
```shell
npx hardhat run scripts/01createUsdtUniV3.ts --network localhost
npx hardhat run scripts/01createPools.ts --network localhost
npx hardhat run scripts/02oracleKeeper.ts --network localhost
npx hardhat run scripts/03executeSupply.ts --network localhost
```
#### Long and Short
```shell
npx hardhat run scripts/11executeLong.ts --network localhost
npx hardhat run scripts/12executeShort.ts --network localhost
```
#### ClosePosition
```shell
npx hardhat run scripts/13executeClosePosition.ts --network localhost
```