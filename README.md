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
Long and Short
```shell
npx hardhat run scripts/0createUsdtUniV3.ts --network localhost
npx hardhat run scripts/1createPools.ts --network localhost
npx hardhat run scripts/2oracleKeeper.ts --network localhost
npx hardhat run scripts/3executeSupply.ts --network localhost
npx hardhat run scripts/5executeDeposit.ts --network localhost
npx hardhat run scripts/11executeLong.ts --network localhost
npx hardhat run scripts/12executeShort.ts --network localhost
```
ClosePosition
```shell
npx hardhat run scripts/0createUsdtUniV3.ts --network testnet
npx hardhat run scripts/1createPools.ts --network testnet
npx hardhat run scripts/2oracleKeeper.ts --network testnet
npx hardhat run scripts/3executeSupply.ts --network testnet
npx hardhat run scripts/13executeClosePosition.ts --network testnet
```
## Testnet
```shell
1.testnet chainId 10086 
2.webSocketUrl and defaultRpcs in utils/network.ts
3.export ACCOUNT_KEY="privateKey for deploy contract and run scripts"
```
Deploy contracts
```shell
npx hardhat ignition deploy ignition/modules/deployExchangeRouter.ts --network testnet
```
Close
```shell
npx hardhat run scripts/0createUsdtUniV3.ts --network testnet
npx hardhat run scripts/1createPools.ts --network testnet
npx hardhat run scripts/2oracleKeeper.ts --network testnet
npx hardhat run scripts/3executeSupply.ts --network testnet
npx hardhat run scripts/14executeClose.ts --network testnet
```