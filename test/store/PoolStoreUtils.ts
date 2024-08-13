import { expect } from "chai";
import { deployContract, logGasUsage } from "../../utils/deploy";
import { parsePool } from "../../utils/helper";
import { deployFixtureStore } from "../../utils/fixture";
import { errorsContract} from "../../utils/error";
import { getPoolCount,getPoolKeys } from "../../utils/pool";
import * as keys from "../../utils/keys";

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

        await roleStore.grantRole(poolStoreUtilsTest.target, keys.CONTROLLER);     

    });
    
    it("get, set, remove", async () => {
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

        let emptyStoreItem = await getEmptyItem();
        const expectedPropsLength = 13;
        expect(Object.keys(emptyStoreItem).length).eq(expectedPropsLength);   
        let sampleItem = parsePool(emptyStoreItem);
        emptyStoreItem = parsePool(emptyStoreItem);
        // Object.keys(sampleItem).forEach((key, index) => {
        //     if (typeof key !== 'bigint') {
        //         sampleItem[key] = accountList[index].address;
        //     }
        // });
        sampleItem.interestRateStrategy = accountList[0].address;
        sampleItem.underlyingAsset = accountList[1].address;
        sampleItem.poolToken = accountList[2].address;
        sampleItem.debtToken = accountList[3].address;
        //console.log(sampleItem);

        const initialItemCount = await getItemCount(dataStore);
        const initialItemKeys = await getItemKeys(dataStore, 0, 10);

        //set item
        await logGasUsage(
            setItem(dataStore, itemKey, sampleItem)
        );   

        let fetchedItem = await getItem(dataStore, itemKey);
        Object.keys(sampleItem).forEach((key) => {
            expect(fetchedItem[key]).deep.eq(sampleItem[key]);
        });
        expect(await getItemCount(dataStore)).eq(initialItemCount + BigInt(1));
        expect(await getItemKeys(dataStore, 0, 10)).deep.equal(initialItemKeys.concat(itemKey));

        //remove item
        await removeItem(dataStore, itemKey, sampleItem);
        fetchedItem = await getItem(dataStore, itemKey);
        fetchedItem = parsePool(fetchedItem);
        Object.keys(fetchedItem).forEach((key) => {
            expect(fetchedItem[key]).deep.eq(emptyStoreItem[key]);
        });

        expect(await getItemCount(dataStore)).eq(initialItemCount);
        expect(await getItemKeys(dataStore, 0, 10)).deep.equal(initialItemKeys);     

    });

}); 