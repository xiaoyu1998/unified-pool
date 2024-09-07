import { expect } from "chai";
import { deployContract } from "../../utils/deploy";
import { bigNumberify, rayMul, rayDiv} from "../../utils/math";
import { MAX_UINT_AMOUNT, RAY, HALF_RAY, WAD, HALF_WAD } from "../../utils/constants";

describe("WadRayMathWrapper", () => {
    let wrapper;

    beforeEach(async () => {
        wrapper = await deployContract("WadRayMathWrapper", []);
    });

    it('Plain getters', async () => {
        expect((await wrapper.wad()).toString()).to.be.eq(WAD);
        expect((await wrapper.halfWad()).toString()).to.be.eq(HALF_WAD);
        expect((await wrapper.ray()).toString()).to.be.eq(RAY);
        expect((await wrapper.halfRay()).toString()).to.be.eq(HALF_RAY);
    });

    it('rayMul()', async () => {
        const a = bigNumberify('134534543232342353231234');
        const b = bigNumberify('13265462389132757665657');

        expect(await wrapper.rayMul(a, b)).to.be.eq(rayMul(a, b));
        expect(await wrapper.rayMul(0, b)).to.be.eq('0');
        expect(await wrapper.rayMul(a, 0)).to.be.eq('0');

        const tooLargeA = (MAX_UINT_AMOUNT - HALF_RAY)/b + bigNumberify(1);
        await expect(wrapper.rayMul(tooLargeA, b)).to.be.reverted;
    });

    it('rayDiv()', async () => {
        const a = bigNumberify('134534543232342353231234');
        const b = bigNumberify('13265462389132757665657');

        expect(await wrapper.rayDiv(a, b)).to.be.eq(rayDiv(a, b));

        const halfB = b/bigNumberify(2);
        const tooLargeA = (MAX_UINT_AMOUNT - halfB)/RAY + bigNumberify(1);

        await expect(wrapper.rayDiv(tooLargeA, b)).to.be.reverted;
        await expect(wrapper.rayDiv(a, 0)).to.be.reverted;
    });

    // it("Mul Div", async () => {
    //     const a = bigNumberify('134534543232342353231234');
    //     let b = bigNumberify('13265462389132757665657');
    //     let count = 0;

    //     for (let i = 0; i < 1000; i++){
    //         b = b + bigNumberify(i)
    //         let mul = await wadRayMathWrapper.rayMul(a, b);
    //         let div = await wadRayMathWrapper.rayDiv(mul, b);
    //         if (a != div){
    //             count ++;
    //             console.log(a, div);
    //         }
    //     }

    //     console.log(count);
    // });


}); 