import hre from "hardhat";
import { deployContractWithStatus, contractAt, contractAtOptions, sendTxn} from "../../utils/deploy";
import { expandDecimals, bigNumberify} from "../../utils/math";
import queryString from "query-string";
import { BigNumber, Interface } from "ethers";
// import { performMulticall } from "../../utils/multicall";

function buildUrl(baseUrl: string, path: string, query?: Record<string, string | number | boolean | undefined>) {
  const qs = query ? `?${queryString.stringify(query)}` : "";

  return `${baseUrl}${path}${qs}`;
}

function fetchPrices(): Promise<TickersResponse> {
  return fetch(buildUrl("https://arbitrum-api.gmxinfra.io", "/prices/tickers"))
    .then((res) => res.json())
    .then((res) => {
      if (!res.length) {
        throw new Error("Invalid tickers response");
      }

      return res;
    })
    .catch((e) => {
      // eslint-disable-next-line no-console
      console.error(e);

      throw e;
    });
}

function parseContractPrice(price: BigNumber, tokenDecimals: number) {
  return price.mul(expandDecimals(1, tokenDecimals));
}

function parsePrice(price: BigNumber, tokenDecimals: number, tokenPricefeedDecimals:number) {
  return price.mul(expandDecimals(1, tokenDecimals)).div(expandDecimals(1, tokenPricefeedDecimals));
}


async function main() {

  const oracle = await hre.gmx.getOracle();
  const tokens = await hre.gmx.getTokens();
  while(true){
    const prices = [];
    await fetchPrices().then((priceItems) => {
      //console.log(priceItems)
      priceItems.forEach((priceItem) => {
        try {
          const oracleConfig = oracle.tokens[priceItem.tokenSymbol];
          // const tokensConfig = tokens[priceItem.tokenSymbol];
          if(oracleConfig ) {
             // const minPrice = parsePrice(BigNumber.from(priceItem.minPrice), tokensConfig.decimals, tokensConfig.pricefeedDecimals);
             // const maxPrice = parsePrice(BigNumber.from(priceItem.maxPrice), tokensConfig.decimals, tokensConfig.pricefeedDecimals);
             const minPrice = BigNumber.from(priceItem.minPrice);
             const maxPrice = BigNumber.from(priceItem.maxPrice);
             prices.push({symbol:priceItem.tokenSymbol, address:oracleConfig.priceFeed.address, price:minPrice.add(maxPrice).div(2)})
          }
        } catch (e) {
          console.log(e);
          return;
        }
      });
     });

    const multicallReadParams = [];
    const pricefeed = await hre.ethers.getContract("MockPriceFeed");
    for (const {symbol, address, price} of prices){    
      console.log(address, symbol, price*1)  
      multicallReadParams.push({
        target: address,
        allowFailure: false,
        callData: pricefeed.interface.encodeFunctionData("setAnswer", [price]),
        label: symbol,
      }); 
    };

    const multicall = await hre.ethers.getContract("Multicall3");
    await sendTxn(multicall.aggregate3(multicallReadParams), "multicall.aggregate3(pricefeed.setAnswer)");
  }

}

// async function main() {

//     const usdcPriceFeed = await contractAtOptions("MockPriceFeed", "0x9A94fe1A77d22b8938f8fbC9c484eBC7d868c48d") 
//     // const wbtcPriceFeed = await contractAtOptions("MockPriceFeed", "0x5d81d8e6625F01CcF7678Fea5018b2acE6BBbD0e");
//     // const wethPriceFeed = await contractAtOptions("MockPriceFeed", "0x703603edf3e7797ea0839e8b2cEb480996827c4E");
//     // const uniPriceFeed = await contractAtOptions("MockPriceFeed", "0x8aE27845f6d3Ed50Cc53f32F11a6165aeBdEF35F");
//     // const solPriceFeed = await contractAtOptions("MockPriceFeed", "0x7b41D154205DeC7E96437ddf89b804CED23196A7");
//      while(true){
//       //await sendTxn(usdcPriceFeed.setAnswer(bigNumberify(800000000)), "usdcPriceFeed.setLatestAnswer(answer)");
//       //await sendTxn(usdcPriceFeed.setAnswer(expandDecimals(1, 8)), "usdcPriceFeed.setLatestAnswer(answer)");
//       // await sendTxn(wbtcPriceFeed.setAnswer(expandDecimals(50000, 8)), "wbtcPriceFeed.setLatestAnswer(answer)");
//       // await sendTxn(wethPriceFeed.setAnswer(expandDecimals(3000, 8)), "wethPriceFeed.setLatestAnswer(answer)");
//       // await sendTxn(uniPriceFeed.setAnswer(expandDecimals(8, 8)), "uniPriceFeed.setLatestAnswer(answer)");
//       // await sendTxn(solPriceFeed.setAnswer(expandDecimals(100, 8)), "solPriceFeed.setLatestAnswer(answer)");
//       }

// }

main()
  .then(() => {
    process.exit(0);
  })
  .catch((ex) => {
    console.error(ex);
    process.exit(1);
  });
