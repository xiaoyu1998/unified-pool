import hre from "hardhat";
import { parseError, getErrorString } from "../utils/error";

function getErrorMsg(errorBytes){
    errorBytes = errorBytes.toLocaleLowerCase();
  if (!errorBytes.startsWith("0x")) {
    errorBytes = "0x" + errorBytes;
  }
  console.log("trying to parse custom error reason", errorBytes);
  try {
    const errorReason = parseError(errorBytes);
    return getErrorString(errorReason);
  } catch (e) {
    console.log(e);
  }
}

async function main() {
  const txHash = "0xd67c78fa43755e768f1641b8226566e93f752d0524972a9443c6edd7eb082cd0";
  const txReceipt = await ethers.provider.getTransactionReceipt(txHash);
  let txRequest = await txReceipt.getTransaction();
  txRequest.maxFeePerGas = undefined;
  txRequest.maxPriorityFeePerGas = undefined;
  try {
      await ethers.provider.call(txRequest);
  } catch (err) {
      console.log("Error:", getErrorMsg(err.data));
  }
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((ex) => {
    console.error(ex);
    process.exit(1);
  });