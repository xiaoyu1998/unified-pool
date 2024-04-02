import hre from "hardhat";
import { getContract, sendTxn, getTokens} from "../utils/deploy";
const { bigNumberify } = require("../utils/math")
import queryString from "query-string";

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

async function main() {
    const multicall = await getContract("Multicall3");
    while(true){
        const prices = [];
        await fetchPrices().then((priceItems) => {
            // console.log(priceItems)
            priceItems.forEach((priceItem) => {
                try {
                    const token = getTokens(priceItem.tokenSymbol);
                    if (token) {
                        const minPrice = bigNumberify(priceItem.minPrice);
                        const maxPrice = bigNumberify(priceItem.maxPrice);
                        prices.push({
                            symbol:priceItem.tokenSymbol, 
                            address:token["oracle"], 
                            price:(minPrice + maxPrice)/bigNumberify(2)
                        })
                    }
                } catch (e) {
                  console.log(e);
                  return;
                }
            });
        });

        // console.log(prices);
        const multicallArgs = [];
        const artifact = await hre.artifacts.readArtifact("MockPriceFeed");
        const oracle = new hre.ethers.Interface(artifact.abi);
        for (const {symbol, address, price} of prices){     
            multicallArgs.push({
                target: address,
                allowFailure: false,
                callData: oracle.encodeFunctionData("setAnswer", [price]),
                label: symbol,
            }); 
        };
        await sendTxn(multicall.aggregate3(multicallArgs), "multicall.aggregate3(oracle.setAnswer)");
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
