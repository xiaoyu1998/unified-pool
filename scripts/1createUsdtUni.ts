const { deployContract, sendTxn, writeTokenAddresses, readTokenAddresses, getTokens, getContract } = require("../utils/deploy")
const { expandDecimals } = require("../utils/math")

async function main() {
  const [owner] = await ethers.getSigners();

  const usdtDecimals = 6;
  const usdtOracleDecimal = 24;
  const uniDecimals = 18;
  const uniOracleDecimal = 24;

  const usdt = await deployContract("MintableToken", ["Tether", "USDT", usdtDecimals])
  const uni = await deployContract("MintableToken", ["UNI", "UNI", uniDecimals])
  await sendTxn(usdt.mint(owner.address, expandDecimals(1000000, usdtDecimals)), `usdt.mint(${owner.address})`)
  await sendTxn(uni.mint(owner.address, expandDecimals(1000, uniDecimals)), `usdt.mint(${owner.address})`)

  const usdtOracle = await deployContract("MockPriceFeed", []);
  const uniOracle = await deployContract("MockPriceFeed", []);

  //set oracle
  const config = await getContract("Config");
  const multicallArgs = [
      config.interface.encodeFunctionData("setOracle", [usdt.target, usdtOracle.target]),
      config.interface.encodeFunctionData("setOracleDecimals", [usdt.target, usdtOracleDecimal]),
      config.interface.encodeFunctionData("setOracle", [uni.target, uniOracle.target]),
      config.interface.encodeFunctionData("setOracleDecimals", [uni.target, uniOracleDecimal]),
  ];
  const tx = await config.multicall(multicallArgs);

  writeTokenAddresses({"USDT": {
      "address":usdt.target, 
      "decimals":usdtDecimals, 
      "oracle":usdtOracle.target,
      "oracleDecimals":usdtOracleDecimal,
  }});

  writeTokenAddresses({"UNI": {
      "address":uni.target, 
      "decimals":uniDecimals, 
      "oracle":uniOracle.target,
      "oracleDecimals":uniOracleDecimal,
  }});

  // console.log(getTokens("usdt")["priceFeed"]);
  console.log(readTokenAddresses());
  console.log("USDT", await usdt.balanceOf(owner.address)); 
  console.log("UNI", await uni.balanceOf(owner.address)); 
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })