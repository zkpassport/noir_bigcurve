use bignum::BigNum;
pub use bignum::{BrainpoolP224t1_Fq, BrainpoolP224t1_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global BRAINPOOLP224t1_PARAM: BigCurveParams<BrainpoolP224t1_Fq> = BigCurveParams {
    a: BrainpoolP224t1_Fq::from_limbs([
        0xd1d787b09f075797da89f57ec8c0fc,
        0xd7c134aa264366862a18302575,
    ]),
    b: BrainpoolP224t1_Fq::from_limbs([
        0xed1ed20da14c08b3bb64f18a60888d,
        0x4b337d934104cd7bef271bf60c,
    ]),
    one: [
        BrainpoolP224t1_Fq::from_limbs([
            0x14762ecb49f8928ac0c76029b4d580,
            0x6ab1e344ce25ff3896424e7ffe,
        ]),
        BrainpoolP224t1_Fq::from_limbs([
            0x0d4b1e41c8cc0d1c6abd5f1a46db4c,
            0x0374e9f5143e568cd23f3f4d7c,
        ]),
    ],
    offset_generator: [
        BrainpoolP224t1_Fq::from_limbs([
            0x36999a6d43deaf1842984306ebaa44,
            0x6e486f1d9274bc61a240ffa1de,
        ]),
        BrainpoolP224t1_Fq::from_limbs([
            0x5d998066be85b8be358e7a02c3199a,
            0x35129fa680af90f692a3e0afff,
        ]),
    ],
    offset_generator_final: [
        BrainpoolP224t1_Fq::from_limbs([
            0x51a1542dbc8ddecf77760b9967d2cb,
            0xd6dc08c74251a1ad3e0645157b,
        ]),
        BrainpoolP224t1_Fq::from_limbs([
            0xf5c551ffb7b456c659b84f2afd466f,
            0xa3175514f81f0dde20ef9b7e56,
        ]),
    ],
};

pub global BRAINPOOLP224t1_SCALAR_SLICES: u32 = 57;
pub type BrainpoolP224t1Scalar = ScalarField<BRAINPOOLP224t1_SCALAR_SLICES>;

#[derive_curve_impl(quote { bignum::BrainpoolP224t1_Fq }, quote { BRAINPOOLP224t1_PARAM })]
pub struct BrainpoolP224t1 {
    pub x: BrainpoolP224t1_Fq,
    pub y: BrainpoolP224t1_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, BrainpoolP224t1_Fq, BrainpoolP224t1_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{BrainpoolP224t1, BRAINPOOLP224t1_SCALAR_SLICES, BrainpoolP224t1Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = BrainpoolP224t1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP224t1_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = BrainpoolP224t1::one();
        let negone = BrainpoolP224t1_Fr::one().neg();
        let scalar = BrainpoolP224t1Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = BrainpoolP224t1::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = BrainpoolP224t1_Fr::from(4);
        let p_minus_4_fr = BrainpoolP224t1_Fr::modulus() - four;
        let p_minus_4 = BrainpoolP224t1Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BrainpoolP224t1_Fr::one();
        let p_minus_5 = BrainpoolP224t1Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = BrainpoolP224t1::one();
        let b = a.neg();
        let points = [a, b];

        let result = BrainpoolP224t1::evaluate_linear_expression(
            points,
            scalars,
            [BrainpoolP224t1::one().neg()],
        );

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // BrainpoolP224t1 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<BrainpoolP224t1_Fq, BRAINPOOLP224t1_SCALAR_SLICES, BrainpoolP224t1>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BrainpoolP224t1_Fr = BrainpoolP224t1_Fr::derive_from_seed(seed);
        let scalar_field = BrainpoolP224t1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
