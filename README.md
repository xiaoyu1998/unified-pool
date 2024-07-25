## Unified Pool Contracts

#### Foundry Support

```shell
curl -L https://foundry.paradigm.xyz | bash
```
#### Add Foundry In Path
```shell
export PATH="$PATH:/from/path/.foundry/bin"
```
#### Download

```shell
git clone git@github.com:xiaoyu1998/up-contracts.git --recursive
```
#### Installation

```shell
npm install
```
#### Run Local Node
```shell
npx hardhat node
```
#### Deploy Contracts
```shell
npx hardhat ignition deploy ignition/modules/deployExchangeRouter.ts --network localhost
```
#### Create Pools and Supply
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