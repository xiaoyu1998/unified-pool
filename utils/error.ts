import hre from "hardhat";
import Errors from "../artifacts/contracts/error/Errors.sol/Errors.json";
export const errorsInterface = new ethers.Interface(Errors.abi);
export const errorsContract = new ethers.Contract(ethers.ZeroAddress, Errors.abi);

export enum ProtocolErrors {
    ERC20_INSUFFICIENT_ALLOWANCE = 'ERC20: insufficient allowance',
    ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE = 'ERC20: transfer amount exceeds balance',
};

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
    const txReceipt = await ethers.provider.getTransactionReceipt(txHash);
    let txRequest = await txReceipt.getTransaction();
    txRequest.maxFeePerGas = undefined;
    txRequest.maxPriorityFeePerGas = undefined;
    let errorMsg = "";
    try {
        await ethers.provider.call(txRequest);
    } catch (err) {
        for (const key in err) {
            if (err.hasOwnProperty(key)) {
                console.log(`${key}: ${err[key]}`);
            }
        }
        errorMsg = getErrorMsg(err.data);
    }

    return errorMsg;
}
