const { contractAtOptions, sendTxn, getContract, getTokens } = require("../utils/deploy")

async function main() {
    const [owner] = await ethers.getSigners();
    
    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader");  
    const poolStoreUtils = await getContract("PoolStoreUtils");  
    const usdtAddress = getTokens("usdt");
    const poolUsdt = await reader.getPool(dataStore.target, usdtAddress);
    const poolTokenAddress = poolUsdt[7];
    const poolToken = await contractAtOptions("PoolToken", poolTokenAddress, {
        libraries: {
            PoolStoreUtils: poolStoreUtils,
        },         
    });

    const balance    = await poolToken.balanceOf(owner.address);
    const scaled     = await poolToken.scaledBalanceOf(owner.address);
    const collateral = await poolToken.balanceOfCollateral(owner.address);

    console.log("balance", balance);
    console.log("scaled", scaled);
    console.log("collateral", collateral);
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })