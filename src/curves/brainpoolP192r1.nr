use bignum::BigNum;
pub use bignum::{BrainpoolP192r1_Fq, BrainpoolP192r1_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global BRAINPOOLP192r1_PARAM: BigCurveParams<BrainpoolP192r1_Fq> = BigCurveParams {
    a: BrainpoolP192r1_Fq::from_limbs([0x39c031fe8685c1cae040e5c69a28ef, 0x6a91174076b1e0e19c]),
    b: BrainpoolP192r1_Fq::from_limbs([0x721d044f4496bcca7ef4146fbf25c9, 0x469a28ef7c28cca3dc]),
    one: [
        BrainpoolP192r1_Fq::from_limbs([0xb033c56cb0f0900a2f5c4853375fd6, 0xc0a0647eaab6a48753]),
        BrainpoolP192r1_Fq::from_limbs([0x5f4828c1490002e6773fa2fa299b8f, 0x14b690866abd5bb88b]),
    ],
    offset_generator: [
        BrainpoolP192r1_Fq::from_limbs([0x565f64a6c86d895a8d61ff56ded4f0, 0xbc8fbc218c269121ff]),
        BrainpoolP192r1_Fq::from_limbs([0x7e686108f39c3c0a0581a8044dc3ab, 0x53943e718f704cd07a]),
    ],
    offset_generator_final: [
        BrainpoolP192r1_Fq::from_limbs([0x04487d77f1dcab4f1054afd1dc6067, 0xb5ee20620dc9854a0b]),
        BrainpoolP192r1_Fq::from_limbs([0x63f06fcba2c6518df3b4a2400aa3ac, 0x65c1d1576fdb76c68b]),
    ],
};

pub global BRAINPOOLP192r1_SCALAR_SLICES: u32 = 49;
pub type BrainpoolP192r1Scalar = ScalarField<BRAINPOOLP192r1_SCALAR_SLICES>;

#[derive_curve_impl(quote { bignum::BrainpoolP192r1_Fq }, quote { BRAINPOOLP192r1_PARAM })]
pub struct BrainpoolP192r1 {
    pub x: BrainpoolP192r1_Fq,
    pub y: BrainpoolP192r1_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, BrainpoolP192r1_Fq, BrainpoolP192r1_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{BrainpoolP192r1, BRAINPOOLP192r1_SCALAR_SLICES, BrainpoolP192r1Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = BrainpoolP192r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP192r1_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = BrainpoolP192r1::one();
        let negone = BrainpoolP192r1_Fr::one().neg();
        let scalar = BrainpoolP192r1Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = BrainpoolP192r1::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = BrainpoolP192r1_Fr::from(4);
        let p_minus_4_fr = BrainpoolP192r1_Fr::modulus() - four;
        let p_minus_4 = BrainpoolP192r1Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BrainpoolP192r1_Fr::one();
        let p_minus_5 = BrainpoolP192r1Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = BrainpoolP192r1::one();
        let b = a.neg();
        let points = [a, b];

        let result = BrainpoolP192r1::evaluate_linear_expression(
            points,
            scalars,
            [BrainpoolP192r1::one().neg()],
        );

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // BrainpoolP192r1 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<BrainpoolP192r1_Fq, BRAINPOOLP192r1_SCALAR_SLICES, BrainpoolP192r1>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BrainpoolP192r1_Fr = BrainpoolP192r1_Fr::derive_from_seed(seed);
        let scalar_field = BrainpoolP192r1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
