import hre from "hardhat";
import { getErrorMsgFromTx } from "../utils/error";

async function main() {
  const txHash = "0xca94e038d2d7e48d59d0589452f0d1328394c709c1085463d01b143a8a454281";
  console.log("Error:", await getErrorMsgFromTx(txHash));
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((ex) => {
    console.error(ex);
    process.exit(1);
  });