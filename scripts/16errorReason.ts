import hre from "hardhat";
import { getErrorMsgFromTx } from "../utils/error";

async function main() {
  const txHash = "0xd67c78fa43755e768f1641b8226566e93f752d0524972a9443c6edd7eb082cd0";
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