import { expect } from "chai";
import { deployContract } from "../../utils/deploy";
import { bigNumberify } from "../../utils/math";

describe("WadRayMathWrapper", () => {
    let wadRayMathWrapper;

    beforeEach(async () => {
        wadRayMathWrapper = await deployContract("WadRayMathWrapper", []);
    });

    it("Mul Div", async () => {
        const a = bigNumberify('134534543232342353231234');
        let b = bigNumberify('13265462389132757665657');
        let count = 0;

        for (let i = 0; i < 1000; i++){
            b = b + bigNumberify(i)
            let mul = await wadRayMathWrapper.rayMul(a, b);
            let div = await wadRayMathWrapper.rayDiv(mul, b);
            if (a != div){
                count ++;
                console.log(a, div);
            }
        }

        console.log(count);
    });


}); 