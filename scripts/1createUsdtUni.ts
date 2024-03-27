const { deployContract, sendTxn } = require("../utils/deploy")
const { expandDecimals } = require("../utils/math")

async function main() {
  const [owner] = await ethers.getSigners();
  const usdt = await deployContract("MintableToken", ["Tether", "USDT", 6])
  const uni = await deployContract("MintableToken", ["UNI", "UNI", 18])
  console.log("usdt", usdt.target);
  console.log("uni", uni.target);
  await sendTxn(usdt.mint(owner.address, expandDecimals(1000000, 6)), "usdt.mint(owner.address)")
  await sendTxn(uni.mint(owner.address, expandDecimals(1000, 18)), "uni.mint(owner.address)")
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })