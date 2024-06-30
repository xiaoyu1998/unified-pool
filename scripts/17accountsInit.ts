import { contractAt, sendTxn, getTokens, getContract, getEventEmitter } from "../utils/deploy";
import { expandDecimals } from "../utils/math";
import { getPool } from "../utils/helper";

async function main() {
    const accounts = await ethers.getSigners();
    const owner = accounts[0];
    const users = accounts.slice(1);

    //transfer usdt and eth
    const usdtDecimals = getTokens("USDT")["decimals"];
    const usdtAddress = getTokens("USDT")["address"];
    const usdt = await contractAt("MintableToken", usdtAddress);
    console.log("usdtAddress", usdtAddress);

    const uniDecimals = getTokens("UNI")["decimals"];
    const uniAddress = getTokens("UNI")["address"];
    const uni = await contractAt("MintableToken", uniAddress);
    const amountUsdt = expandDecimals(10000, usdtDecimals);
    const amountUni = expandDecimals(100, uniDecimal7s);
    
    console.log("owner usdt",await usdt.balanceOf(owner)); 
    console.log("owner uni",await uni.balanceOf(owner)); 

    //transfer usdt and eth
    for (const user of users) {
        const amountEth = expandDecimals(1, 18);
        await sendTxn(
            usdt.transfer(user, amountUsdt), `usdt.transfer(${user.address} ${amountUsdt})`
        );

         await sendTxn(
            uni.transfer(user, amountUni), `uni.transfer(${user.address} ${amountUni})`
        );

        await sendTxn(
            owner.sendTransaction({to:user, value:amountEth}), `owner.transfer(${user.address} ${amountEth})`
        );
    };

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })