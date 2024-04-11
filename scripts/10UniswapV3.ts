import { contractAt, sendTxn, getDeployedContractAddresses, getTokens, getContract, getContractAt } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPoolInfo, getLiquidity, getDebt} from "../utils/helper";
import { FeeAmount} from "../utils/constants";
import {
  abi as FACTORY_ABI,
  bytecode as FACTORY_BYTECODE,
} from '@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'


const { mine } = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
    const [owner] = await ethers.getSigners();

    const usdtAddress = getTokens("USDT")["address"];
    const uniAddress = getTokens("UNI")["address"];

    const contractFactory = new ethers.ContractFactory(FACTORY_ABI, FACTORY_BYTECODE, owner);
    const factory = await contractFactory.deploy();
    await factory.createPool(usdtAddress, uniAddress, FeeAmount.MEDIUM);

    console.log(await factory.getPool(usdtAddress, uniAddress, FeeAmount.MEDIUM));

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })