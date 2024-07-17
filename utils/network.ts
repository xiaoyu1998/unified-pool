export const assetAddresses = {
	localhost : "ignition/deployments/chain-31337/underlyAsset_addresses.json",
	localnet : "ignition/deployments/chain-1998/underlyAsset_addresses.json",
	testnet : "deployments/testnet_underlyasset_addresses.json",
	sepolia : "deployments/sepolia_underlyasset_addresses.json",	
};

export const deployAddresses = {
	localhost : "ignition/deployments/chain-31337/deployed_addresses.json",
	localnet : "ignition/deployments/chain-1998/deployed_addresses.json",
	testnet : "deployments/testnet_deployed_addresses.json",
	sepolia : "deployments/sepolia_deployed_addresses.json",
};

export const webSocketUrl = {
	localhost : "ws://127.0.0.1:8545",
	localnet : "ws://192.168.2.106:8545",
	testnet : "ws://35.78.21.3:56109",
};

export const defaultRpcs = {
	localnet: "http://192.168.2.106:8545",
	testnet: "https://spinnergo.online/bdw234131sdf/api/v1/rpc",
	sepolia: "https://sepolia.infura.io/v3/",
};
