const { contractAtOptions, sendTxn } = require("../utils/deploy")
import { hashString } from "../utils/hash";

async function main() {
    const [owner] = await ethers.getSigners();
    console.log(owner.address);
    const roleStore = await contractAtOptions("RoleStore", "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",);
    await sendTxn(
        roleStore.grantRole(owner.address, hashString("CONTROLLER")),
        "roleStore.grantRole(${owner.address}, CONTROLLER})"
    );    
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })