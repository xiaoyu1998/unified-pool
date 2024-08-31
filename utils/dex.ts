
import { expect } from "chai";
import { errorsContract } from "./error";
import { expandDecimals } from "./math"
import * as keys from "./keys";

export function getDexCount(dataStore) {
    return dataStore.getBytes32Count(keys.DEX_LIST);
}

export function getDexKeys(dataStore, start, end) {
    return dataStore.getBytes32ValuesAt(keys.DEX_LIST, start, end);
}

