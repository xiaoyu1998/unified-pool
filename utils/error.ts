import hre from "hardhat";
import Errors from "../artifacts/contracts/error/Errors.sol/Errors.json";
export const errorsInterface = new ethers.Interface(Errors.abi);
export const errorsContract = new ethers.Contract(ethers.ZeroAddress, Errors.abi);

export function getErrorString(error) {
    return JSON.stringify({
        name: error.name,
        args: error.args.map((value) => value.toString()),
    });
}

export function parseError(reasonBytes) {
    try {
        const reason = errorsInterface.parseError(reasonBytes);
        return reason;
    } catch (e) {
        throw new Error(`Could not parse errorBytes ${reasonBytes}`);
    }
}

export function getErrorMsg(errorBytes){
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

export async function getErrorMsgFromTx(txHash){
    //const txHash = "0xd67c78fa43755e768f1641b8226566e93f752d0524972a9443c6edd7eb082cd0";
    const txReceipt = await ethers.provider.getTransactionReceipt(txHash);
    let txRequest = await txReceipt.getTransaction();
    txRequest.maxFeePerGas = undefined;
    txRequest.maxPriorityFeePerGas = undefined;
    let errorMsg = "";
    try {
        await ethers.provider.call(txRequest);
    } catch (err) {
        //console.log("Error:", getErrorMsg(err.data));
        errorMsg = getErrorMsg(err.data);
    }

    return errorMsg;
}
