import { expect } from "chai";
import { deployContract, logGasUsage } from "../../utils/deploy";
import { parseDex } from "../../utils/helper";
import { deployFixtureStore } from "../../utils/fixture";
import { errorsContract} from "../../utils/error";
import { getDexCount, getDexKeys } from "../../utils/dex";
import { hashString } from "../../utils/hash";
import * as keys from "../../utils/keys";

describe("DexStoreUtils", () => {
    let fixture;
    let roleStore, dataStore, dexStoreUtils, reader, dexStoreUtilsTest;
    let accountList;

    beforeEach(async () => {
        fixture = await deployFixtureStore();
        ({  roleStore, 
            dataStore,
            dexStoreUtils,
            reader
         } = fixture.contracts); 
        ( accountList = fixture.accountList);

        dexStoreUtilsTest = await deployContract("DexStoreUtilsTest", [], {
            libraries: {
                DexStoreUtils: dexStoreUtils,
            },
        });    

        await roleStore.grantRole(dexStoreUtilsTest.target, keys.CONTROLLER);     

    });
    
    it("get, set, remove", async () => {
        const itemKey = keys.dexKey(accountList[0].address, accountList[1].address);

        const getEmptyItem = dexStoreUtilsTest.getEmptyDex;
        const getItem = async (dataStore, underlyingAssetA, underlyingAssetB) => {
            return await reader.getDex(dataStore.target, underlyingAssetA, underlyingAssetB);
        }; 

        const getItemCount = getDexCount;
        const getItemKeys = getDexKeys;
        const setItem = async (dataStore, underlyingAssetA, underlyingAssetB, sampleItem) => {
            return await dexStoreUtilsTest.setDex(dataStore.target, underlyingAssetA, underlyingAssetB, sampleItem);
        };
        const removeItem = async (dataStore, underlyingAssetA, underlyingAssetB) => {
            return await dexStoreUtilsTest.removeDex(dataStore.target, underlyingAssetA, underlyingAssetB);
        };

        let emptyStoreItem = await getEmptyItem();
        const expectedPropsLength = 42;
        expect(Object.keys(emptyStoreItem).length).eq(expectedPropsLength);   
        let sampleItem = accountList[0].address;

        const initialItemCount = await getItemCount(dataStore);
        const initialItemKeys = await getItemKeys(dataStore, 0, 10);

        //set item
        await logGasUsage(
            setItem(dataStore, accountList[0].address, accountList[1].address, sampleItem)
        );   

        let fetchedItem = await getItem(dataStore, accountList[0].address, accountList[1].address);
        expect(fetchedItem).deep.eq(sampleItem);

        expect(await getItemCount(dataStore)).eq(initialItemCount + BigInt(1));
        expect(await getItemKeys(dataStore, 0, 10)).deep.equal(initialItemKeys.concat(itemKey));

        //remove item
        await removeItem(dataStore, accountList[0].address, accountList[1].address);
        fetchedItem = await getItem(dataStore, accountList[0].address, accountList[1].address);
        expect(fetchedItem).deep.eq(ethers.ZeroAddress);

        expect(await getItemCount(dataStore)).eq(initialItemCount);
        expect(await getItemKeys(dataStore, 0, 10)).deep.equal(initialItemKeys);     

    });

}); 