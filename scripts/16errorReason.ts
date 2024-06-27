import hre from "hardhat";
import { getErrorMsg } from "../utils/error";

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