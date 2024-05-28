
import { expect } from "chai";
import { errorsContract } from "./error";
import { expandDecimals } from "./math"

export async function testPoolConfiguration(
    config, 
    exchangeRouter, 
    account, 
    testEntry, 
    underlyingAsset, 
    params
) {

        const multicallArgsConfig = [
            config.interface.encodeFunctionData("setPoolActive", [underlyingAsset.target, false]),
            config.interface.encodeFunctionData("setPoolFrozen", [underlyingAsset.target, false]),
            config.interface.encodeFunctionData("setPoolPaused", [underlyingAsset.target, false]),
        ];
        await config.multicall(multicallArgsConfig);

        const multicallArgsSupply = [
            exchangeRouter.interface.encodeFunctionData(testEntry, [params]),
        ];
        await expect(
            exchangeRouter.connect(account).multicall(multicallArgsSupply)
        ).to.be.revertedWithCustomError(errorsContract, "PoolIsInactive");  

        //PoolIsFrozen
        const multicallArgsConfig2 = [
            config.interface.encodeFunctionData("setPoolActive", [underlyingAsset.target, true]),
            config.interface.encodeFunctionData("setPoolFrozen", [underlyingAsset.target, true]),
            config.interface.encodeFunctionData("setPoolPaused", [underlyingAsset.target, false]),
        ];
        await config.multicall(multicallArgsConfig2);   
        await expect(
            exchangeRouter.connect(account).multicall(multicallArgsSupply)
        ).to.be.revertedWithCustomError(errorsContract, "PoolIsFrozen");  

        //PoolIsPaused
        const multicallArgsConfig3 = [
            config.interface.encodeFunctionData("setPoolActive", [underlyingAsset.target, true]),
            config.interface.encodeFunctionData("setPoolFrozen", [underlyingAsset.target, false]),
            config.interface.encodeFunctionData("setPoolPaused", [underlyingAsset.target, true]),
        ];
        await config.multicall(multicallArgsConfig3);   
        await expect(
            exchangeRouter.connect(account).multicall(multicallArgsSupply)
        ).to.be.revertedWithCustomError(errorsContract, "PoolIsPaused"); 

}

