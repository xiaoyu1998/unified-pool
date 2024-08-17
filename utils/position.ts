
import { expect } from "chai";
import { errorsContract } from "./error";
import { expandDecimals } from "./math"
import * as keys from "./keys";

export function getPositionCount(dataStore) {
    return dataStore.getBytes32Count(keys.POSITION_LIST);
}

export function getPositionKeys(dataStore, start, end) {
    return dataStore.getBytes32ValuesAt(keys.POSITION_LIST, start, end);
}

