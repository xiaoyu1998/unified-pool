import { expect } from "chai";
import { deployContract, logGasUsage } from "../../utils/deploy";
import { parsePosition } from "../../utils/helper";
import { deployFixtureStore } from "../../utils/fixture";
import { errorsContract} from "../../utils/error";
import { getPositionCount, getPositionKeys } from "../../utils/position";
import { hashString } from "../../utils/hash";
import * as keys from "../../utils/keys";

describe("PositionStoreUtils", () => {
    let fixture;
    let roleStore, dataStore, positionStoreUtils, reader, positionStoreUtilsTest;
    let accountList;

    beforeEach(async () => {
        fixture = await deployFixtureStore();
        ({  roleStore, 
            dataStore,
            positionStoreUtils,
            reader
         } = fixture.contracts); 
        ( accountList = fixture.accountList);

        positionStoreUtilsTest = await deployContract("PositionStoreUtilsTest", [], {
            libraries: {
                PositionStoreUtils: positionStoreUtils,
            },
        });    

        await roleStore.grantRole(positionStoreUtilsTest.target, keys.CONTROLLER);     

    });
    
    it("get, set, remove", async () => {
        const itemKey = hashString("POSITION_KEY");

        const getEmptyItem = positionStoreUtilsTest.getEmptyPosition;
        const getItem = async (dataStore, key) => {
            return await reader.getPosition(dataStore.target, key);
        }; 

        const getItemCount = getPositionCount;
        const getItemKeys = getPositionKeys;
        const setItem = async (dataStore, key, sampleItem) => {
            return await positionStoreUtilsTest.setPosition(dataStore.target, key, sampleItem);
        };
        const removeItem = async (dataStore, itemKey, account) => {
            return await positionStoreUtilsTest.removePosition(dataStore.target, itemKey, account);
        };

        let emptyStoreItem = await getEmptyItem();
        const expectedPropsLength = 9;
        expect(Object.keys(emptyStoreItem).length).eq(expectedPropsLength);   
        let sampleItem = parsePosition(emptyStoreItem);
        emptyStoreItem = parsePosition(emptyStoreItem);
        sampleItem.account = accountList[0].address;
        sampleItem.underlyingAsset = accountList[1].address;
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
        await removeItem(dataStore, itemKey, accountList[0].address);
        fetchedItem = await getItem(dataStore, itemKey);
        fetchedItem = parsePosition(fetchedItem);
        Object.keys(fetchedItem).forEach((key) => {
            expect(fetchedItem[key]).deep.eq(emptyStoreItem[key]);
        });

        expect(await getItemCount(dataStore)).eq(initialItemCount);
        expect(await getItemKeys(dataStore, 0, 10)).deep.equal(initialItemKeys);     

    });

}); 