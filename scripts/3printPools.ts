const { contractAtOptions, sendTxn, getDeployedContractAddresses } = require("../utils/deploy")

async function main() {
    // const [owner] = await ethers.getSigners();
    
    const poolStoreUtilsAddress = getDeployedContractAddresses("PoolStoreUtils");
    const positionStoreUtilsAddress = getDeployedContractAddresses("PositionStoreUtils");
    const readerAddress = getDeployedContractAddresses("Reader");
    const dataStoreAddress = getDeployedContractAddresses("DataStore");

    const poolStoreUtils = await contractAtOptions("PoolStoreUtils", poolStoreUtilsAddress);
    const positionStoreUtils = await contractAtOptions("PositionStoreUtils", positionStoreUtilsAddress);
    const reader = await contractAtOptions("Reader", readerAddress, {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
            PositionStoreUtils: positionStoreUtils
        },         
    });

    const dataStore = await contractAtOptions("DataStore", dataStoreAddress);
    const pools = await reader.getPools(dataStore.target, 0, 10);
    console.log(pools)

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })