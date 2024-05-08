import hre from "hardhat";
import { getContract, sendTxn, getTokens, getWebSocketContract} from "../utils/deploy";
import  { bigNumberify } from "../utils/math";
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

    const uniOracleAddress = getTokens("UNI")["oracle"];
    const artifactAggregator = await hre.artifacts.readArtifact("MockAggregator");
    const uniOracle = await getWebSocketContract(undefined, artifactAggregator.abi, artifactAggregator.bytecode, uniOracleAddress);
    uniOracle.on("AnswerUpdated", (answer, lastestRound, updateAt) => {
        console.log("AnswerUpdated" , answer, lastestRound, updateAt);
    }); 
    uniOracle.on("NewRound", (lastestRound, sender, startAt) =>{
        console.log("NewRound" , lastestRound, sender, startAt);
    }); 

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

        console.log(prices);
        const multicallArgs = [];
        const artifact = await hre.artifacts.readArtifact("MockAggregator");
        const oracle = new hre.ethers.Interface(artifact.abi);
        for (const {symbol, address, price} of prices){     
            multicallArgs.push({
                target: address,
                allowFailure: false,
                callData: oracle.encodeFunctionData("setAnswer", [price]),
                label: symbol,
            }); 
        };
        await sendTxn(
            multicall.aggregate3(multicallArgs),
            "multicall.aggregate3"
        );
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
