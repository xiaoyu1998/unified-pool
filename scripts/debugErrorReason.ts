import hre from "hardhat";

import { parseError, getErrorString } from "../utils/error";


let errorBytes =
"0x4e487b710000000000000000000000000000000000000000000000000000000000000011";

async function main() {
  errorBytes = errorBytes.toLocaleLowerCase();
  if (!errorBytes.startsWith("0x")) {
    errorBytes = "0x" + errorBytes;
  }

  console.log("trying to parse custom error reason", errorBytes);

  try {
    const errorReason = parseError(errorBytes);
    console.log("error:", getErrorString(errorReason));
    return;
  } catch (e) {
    console.log(e);
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