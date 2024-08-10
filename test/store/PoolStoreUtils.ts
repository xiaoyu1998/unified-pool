import { expect } from "chai";
import { deployContract } from "../../utils/deploy";
import { deployFixtureStore } from "../../utils/fixture";
import { errorsContract} from "../../utils/error";
import { getPoolCount,getPoolKeys } from "../../utils/pool";

describe("PoolStoreUtils", () => {
    let fixture;
    let roleStore, dataStore, poolStoreUtils, reader, poolStoreUtilsTest;
    let accountList;

    beforeEach(async () => {
        fixture = await deployFixtureStore();
        ({  roleStore, 
            dataStore,
            poolStoreUtils,
            reader
         } = fixture.contracts); 
        ( accountList = fixture.accountList);

        poolStoreUtilsTest = await deployContract("PoolStoreUtilsTest", [], {
            libraries: {
                PoolStoreUtils: poolStoreUtils,
            },
        });        

    });
    
    it("get, set, remove", async () => {
        const sampleItem = {};
        const itemKey = accountList[accountList.length - 1].address;

        const getEmptyItem = poolStoreUtilsTest.getEmptyPool;
        const getItem = async (dataStore, key) => {
          return await reader.getPool(dataStore.target, key);
        }; 

        const getItemCount = getPoolCount;
        const getItemKeys = getPoolKeys;
        const setItem = async (dataStore, key, sampleItem) => {
            return await poolStoreUtilsTest.setPool(dataStore.target, key, sampleItem);
        };
        const removeItem = async (dataStore, itemKey) => {
            return await poolStoreUtilsTest.removePool(dataStore.target, itemKey);
        };

        const emptyStoreItem = await getEmptyItem();
        const expectedPropsLength = 13;
        expect(Object.keys(emptyStoreItem).length).eq(expectedPropsLength);        


    });

    

}); 