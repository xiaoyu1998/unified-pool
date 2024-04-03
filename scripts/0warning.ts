import { contractAt, sendTxn, getDeployedContractAddresses, getTokens, getContract, getContractAt } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPool, getLiquidity, getDebt} from "../utils/helper";
import { WithdrawUtils } from "../typechain-types/contracts/exchange/SupplyHandler";

// ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR);
async function main() {
    const [owner] = await ethers.getSigners();


    // const oracleStoreUtils = getDeployedContractAddresses("OracleStoreUtils");
    // return await contractAt("OracleStoreUtils", oracleStoreUtils);

    const artifact = await hre.artifacts.readArtifact("OracleStoreUtils");
    const oracle = new ethers.Interface(artifact.abi);


}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })