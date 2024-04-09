import { contractAt, sendTxn, getDeployedContractAddresses, getTokens, getContract, getContractAt } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getLiquidity, getDebt} from "../utils/helper";

const { mine } = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
    const [owner] = await ethers.getSigners();

    const dataStore = await getContract("DataStore");   
    const reader = await getContract("Reader"); 

    await mine(10000);
    const usdtAddress = getTokens("USDT")["address"];
    const poolUsdt = await getPoolInfo(usdtAddress);
    const poolToken = await getContractAt("PoolToken", poolUsdt.poolToken); 
    const debtToken = await getContractAt("DebtToken", poolUsdt.debtToken);
    console.log("poolUsdt", poolUsdt);
    console.log("pools",await getPoolsLiquidityAndDebt(dataStore, reader));
    console.log("account",await getAccountLiquidityAndDebtInPools(dataStore, reader, owner.address));
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })