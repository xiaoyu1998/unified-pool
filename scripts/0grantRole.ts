const { contractAtOptions, sendTxn } = require("../utils/deploy")
import { hashString } from "../utils/hash";
import * as keys from "../utils/keys";

async function main() {
    const [owner] = await ethers.getSigners();
    const roleStore = await getContract("RoleStore");  
    await sendTxn(
        roleStore.grantRole("0x202CCe504e04bEd6fC0521238dDf04Bc9E8E15aB", keys.CONTROLLER),
        "roleStore.grantRole(Config, CONTROLLER})"
    ); 

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })