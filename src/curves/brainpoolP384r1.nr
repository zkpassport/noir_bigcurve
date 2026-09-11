use bignum::BigNum;
pub use bignum::{BrainpoolP384r1_Fq, BrainpoolP384r1_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global BRAINPOOLP384r1_PARAM: BigCurveParams<BrainpoolP384r1_Fq> = BigCurveParams {
    a: BrainpoolP384r1_Fq::from_limbs([
        0xa5814a503ad4eb04a8c7dd22ce2826,
        0xa28e4fb22787139165efba91f90f8a,
        0xc63d8c150c3c72080ace05afa0c2be,
        0x7bc382,
    ]),
    b: BrainpoolP384r1_Fq::from_limbs([
        0xb4390295dbc9943ab78696fa504c11,
        0x7de107dcd2a62e880ea53eeb62d57c,
        0xdd22ce28268b39b55416f0447c2fb7,
        0x04a8c7,
    ]),
    one: [
        BrainpoolP384r1_Fq::from_limbs([
            0x26e03436d646aaef87b2e247d4af1e,
            0xa3e77ef14fe3db7fcafe0cbd10e8e8,
            0xf068cf45ffa2a63a81b7c13f6b8847,
            0x1d1c64,
        ]),
        BrainpoolP384r1_Fq::from_limbs([
            0x4646217791811142820341263c5315,
            0x0b29feec5864e19c054ff99129280e,
            0x7520f9c2a45cb1eb8e95cfd55262b7,
            0x8abe1d,
        ]),
    ],
    offset_generator: [
        BrainpoolP384r1_Fq::from_limbs([
            0xa8953d5583c124771c6721ef05d086,
            0xc03069b018b033380aa83281aca2e8,
            0xba12077ad49dacf80f99bddf5a72de,
            0x4a19c2,
        ]),
        BrainpoolP384r1_Fq::from_limbs([
            0xbb13d9d820e460fd495f75e517600b,
            0x6e76c50732c6c2e3c88e89ab3e3fa1,
            0xb249b2aedc4b1fad8b44480f55f1a6,
            0x61ee23,
        ]),
    ],
    offset_generator_final: [
        BrainpoolP384r1_Fq::from_limbs([
            0x9135fb619526332f92e4d98e9f4d3b,
            0xfceac0722de4c562917ada7efbd2b8,
            0x6e0db675f35c49a17f84efd20c4617,
            0x691f43,
        ]),
        BrainpoolP384r1_Fq::from_limbs([
            0xb4cf97424e3cad25585150bc0eb22d,
            0x483354f79803ed05cf139c2c3842c2,
            0x450e47f0387e7feb0d36ff843b4b96,
            0x16a6,
        ]),
    ],
};

pub global BRAINPOOLP384r1_SCALAR_SLICES: u32 = 97;
pub type BrainpoolP384r1Scalar = ScalarField<BRAINPOOLP384r1_SCALAR_SLICES>;

#[derive_curve_impl(quote { bignum::BrainpoolP384r1_Fq }, quote { BRAINPOOLP384r1_PARAM })]
pub struct BrainpoolP384r1 {
    pub x: BrainpoolP384r1_Fq,
    pub y: BrainpoolP384r1_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, BrainpoolP384r1_Fq, BrainpoolP384r1_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{BrainpoolP384r1, BRAINPOOLP384r1_SCALAR_SLICES, BrainpoolP384r1Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = BrainpoolP384r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP384r1_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = BrainpoolP384r1::one();
        let negone = BrainpoolP384r1_Fr::one().neg();
        let scalar = BrainpoolP384r1Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = BrainpoolP384r1::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = BrainpoolP384r1_Fr::from(4);
        let p_minus_4_fr = BrainpoolP384r1_Fr::modulus() - four;
        let p_minus_4 = BrainpoolP384r1Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BrainpoolP384r1_Fr::one();
        let p_minus_5 = BrainpoolP384r1Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = BrainpoolP384r1::one();
        let b = a.neg();
        let points = [a, b];

        let result = BrainpoolP384r1::evaluate_linear_expression(
            points,
            scalars,
            [BrainpoolP384r1::one().neg()],
        );

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // BrainpoolP384r1 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<BrainpoolP384r1_Fq, BRAINPOOLP384r1_SCALAR_SLICES, BrainpoolP384r1>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BrainpoolP384r1_Fr = BrainpoolP384r1_Fr::derive_from_seed(seed);
        let scalar_field = BrainpoolP384r1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
