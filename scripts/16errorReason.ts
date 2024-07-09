import hre from "hardhat";
import { getErrorMsgFromTx } from "../utils/error";

async function main() {
  const txHash = "0xe0b54d92266d4d01378b1c993e542261e205ecfa5c2790396cdd180afef39ff1";
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