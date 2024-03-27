#Unify Pool

Try running some of the following tasks:

installation

```shell
npm install
```
run local node
```shell
npx hardhat node
```
deplopy contracts
```shell
npx hardhat ignition deploy ignition/modules/deployExchangeRouter.ts --network localhost
```
create pools and print states
```shell
npx hardhat run scripts/2createPools.ts --network localhost
npx hardhat run scripts/3printPools.ts --network localhost
```