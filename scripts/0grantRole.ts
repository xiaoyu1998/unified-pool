const { contractAtOptions, sendTxn } = require("../utils/deploy")
import { hashString } from "../utils/hash";
import * as keys from "../utils/keys";

async function main() {
    const [owner] = await ethers.getSigners();
    console.log(owner.address);
    const roleStore = await contractAtOptions("RoleStore", "0x82e01223d51Eb87e16A03E24687EDF0F294da6f1",);
    // await sendTxn(
    //     roleStore.grantRole(owner.address, keys.CONTROLLER),
    //     "roleStore.grantRole(${owner.address}, CONTROLLER})"
    // ); 

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