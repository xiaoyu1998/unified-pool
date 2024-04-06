import { contractAt, sendTxn, getDeployedContractAddresses, getTokens, getContract, getContractAt } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPool, getLiquidity, getDebt} from "../utils/helper";
import OracleStoreUtils from "../artifacts/contracts/oracle/OracleStoreUtils.sol/OracleStoreUtils.json";

async function main() {
    //console.log(OracleStoreUtils);
    const oracle = new ethers.Interface(OracleStoreUtils.abi);


}



main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })