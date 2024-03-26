import { DeployFunction, DeployResult, DeploymentsExtension } from "hardhat-deploy/dist/types";

export async function sendTxn(txnPromise, label) {
  console.info(`Processsing ${label}:`)
  const txn = await txnPromise
  console.info(`Sending ${label}...`)
  await txn.wait(1)
  console.info(`... Sent! ${txn.hash}`)
  return txn
}

export async function deployContract(name, args, contractOptions = {}) {
  const contractFactory = await ethers.getContractFactory(name, contractOptions);
  return await contractFactory.deploy(...args);
}

export async function contractAt(name, address, options, provider) {
  let contractFactory = await ethers.getContractFactory(name);
  if (provider) {
    contractFactory = contractFactory.connect(provider);
  }
  return await contractFactory.attach(address);
}