const { contractAtOptions, sendTxn, getContract, getContractAt, getTokens } = require("../utils/deploy")
import { getPool,  getLiquidity, getDebt} from "../utils/helper";

async function main() {
    const [owner] = await ethers.getSigners();
    
    const usdtAddress = getTokens("usdt");
    const poolUsdt = await getPool(usdtAddress);
    const poolToken = await getContractAt("PoolToken", poolUsdt.poolToken);
    const debtToken = await getContractAt("DebtToken", poolUsdt.debtToken);
    
    console.log(await getLiquidity(poolToken, owner.address));
    console.log(await getDebt(debtToken, owner.address));
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })