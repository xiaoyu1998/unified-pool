
import { getContract } from "./deploy";

export async function deployFixture() {
  const chainId = 31337; // hardhat chain id
  const accountList = await ethers.getSigners();
  const [
    wallet,
    user0,
    user1,
    user2,
    user3,
    user4,
    user5,
    user6,
    user7,
    user8,
    signer0,
    signer1,
    signer2,
    signer3,
    signer4,
    signer5,
    signer6,
    signer7,
    signer8,
    signer9,
  ] = accountList;

  const roleStore = await getContract("RoleStore");
  const dataStore = await getContract("DataStore");   
  const router = await getContract("Router");
  const exchangeRouter = await getContract("ExchangeRouter"); 
  const reader = await getContract("Reader"); 
  const eventEmitter = await getContract("EventEmitter"); 
  const config = await getContract("Config");

  return {
    accountList,
    getContract: async (contractName) => {
      return await getContract(contractName);
    },
    accounts: {
      wallet,
      user0,
      user1,
      user2,
      user3,
      user4,
      user5,
      user6,
      user7,
      user8,
      signer0,
      signer1,
      signer2,
      signer3,
      signer4,
      signer5,
      signer6,
      signer7,
      signer8,
      signer9,
      signers: [signer0, signer1, signer2, signer3, signer4, signer5, signer6],
    },
    contracts: {
      roleStore,
      dataStore,
      router,
      exchangeRouter,
      reader,
      dataStore,
      eventEmitter,
      config,
    },
    props: { signerIndexes: [0, 1, 2, 3, 4, 5, 6], executionFee: "1000000000000000" },
  };
}
