import { hashString, hashData } from "./hash";

export const CONFIG_KEEPER = hashString("CONFIG_KEEPER");
export const POOL_KEEPER = hashString("POOL_KEEPER");
export const CONTROLLER = hashString("CONTROLLER");
export const ROUTER_PLUGIN = hashString("ROUTER_PLUGIN");
export const POOL_LIST = hashString("POOL_LIST");
export const POSITION_LIST = hashString("POSITION_LIST");
export const DEX = hashString("DEX");
export const DEX_LIST = hashString("DEX_LIST");

export function dexKey(underlyingAssetA, underlyingAssetB){
	let [token0, token1] = (underlyingAssetA < underlyingAssetB) 
		?[underlyingAssetA, underlyingAssetB]
		:[underlyingAssetB, underlyingAssetA];
	return hashData(
		["bytes32", "address", "address"], 
		[DEX, token0, token1]
	);
}
