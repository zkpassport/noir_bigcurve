use bignum::BigNum;
pub use bignum::{BrainpoolP512t1_Fq, BrainpoolP512t1_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global BRAINPOOLP512t1_PARAM: BigCurveParams<BrainpoolP512t1_Fq> = BigCurveParams {
    a: BrainpoolP512t1_Fq::from_limbs([
        0x81ff2f2d82c68528aa6056583a48f0,
        0x9b009bc66842aecda12ae6a380e628,
        0xb3b3c9d20ed6639cca703308717d4d,
        0xdbe9c48b3fd4e6ae33c9fc07cb308d,
        0xaadd9db8,
    ]),
    b: BrainpoolP512t1_Fq::from_limbs([
        0x2553b465763689180ea2571867423e,
        0xfa2304976540f6450085f2dae145c2,
        0x0bcb4981527897504bec3e36a62bcd,
        0x441cfab76e1890e46884eae321f70c,
        0x7cbbbcf9,
    ]),
    one: [
        BrainpoolP512t1_Fq::from_limbs([
            0xa3f25fe26f06b51baa2696fa9035da,
            0x51735cdb3ea499aa77a7d6943a64f7,
            0x2458c56dde9db1758d39c0313d82ba,
            0x12788717b9c1ba06cbc2a6feba8584,
            0x640ece5c,
        ]),
        BrainpoolP512t1_Fq::from_limbs([
            0x6ecff96dbb8bace198b61e00f8b332,
            0x2184beef216bd71df2dadf86a62730,
            0x19b71634c01131159cae03cee9d993,
            0x95f5af0fa2c892376c84ace1bb4e30,
            0x5b534bd5,
        ]),
    ],
    offset_generator: [
        BrainpoolP512t1_Fq::from_limbs([
            0xf4213653b62b6886b2c20f4796081e,
            0xf03dd3fb7537d6bca13ef70657b182,
            0x680b6afa8a0891b3e42256b18e01ba,
            0x9705a7235ccb62fc0e82e83721a252,
            0x6c63942e,
        ]),
        BrainpoolP512t1_Fq::from_limbs([
            0x8dde19568ad66a50b596b644d673c7,
            0x31ae22cbfc5e02b14b41fa2127d965,
            0x2f350ef7ff95aa627306d6e6624f08,
            0x6ddcd68baea8a6930f26bf5d3e9d8b,
            0x5ea646c4,
        ]),
    ],
    offset_generator_final: [
        BrainpoolP512t1_Fq::from_limbs([
            0xe3266e9180322d3ef6509688000da3,
            0x72c6ce9316a2d5239c393dd2fb7bb6,
            0x63a61a0733f91cc3c5aa305b20710e,
            0x67111dcdb5a7decd1f4d5b278ae3fe,
            0x83ebf511,
        ]),
        BrainpoolP512t1_Fq::from_limbs([
            0xd0e4240651eab57d95784c2389a7c0,
            0x33d917809e0e4e82645df6cfd11395,
            0xcf53695f086659f6b7f82272f079c1,
            0xe6cfea893bbb433fd7933f344af848,
            0x3561ec34,
        ]),
    ],
};

pub global BRAINPOOLP512t1_SCALAR_SLICES: u32 = 129;
pub type BrainpoolP512t1Scalar = ScalarField<BRAINPOOLP512t1_SCALAR_SLICES>;

#[derive_curve_impl(quote { bignum::BrainpoolP512t1_Fq }, quote { BRAINPOOLP512t1_PARAM })]
pub struct BrainpoolP512t1 {
    pub x: BrainpoolP512t1_Fq,
    pub y: BrainpoolP512t1_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, BrainpoolP512t1_Fq, BrainpoolP512t1_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{BrainpoolP512t1, BRAINPOOLP512t1_SCALAR_SLICES, BrainpoolP512t1Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = BrainpoolP512t1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP512t1_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = BrainpoolP512t1::one();
        let negone = BrainpoolP512t1_Fr::one().neg();
        let scalar = BrainpoolP512t1Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = BrainpoolP512t1::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = BrainpoolP512t1_Fr::from(4);
        let p_minus_4_fr = BrainpoolP512t1_Fr::modulus() - four;
        let p_minus_4 = BrainpoolP512t1Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BrainpoolP512t1_Fr::one();
        let p_minus_5 = BrainpoolP512t1Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = BrainpoolP512t1::one();
        let b = a.neg();
        let points = [a, b];

        let result = BrainpoolP512t1::evaluate_linear_expression(
            points,
            scalars,
            [BrainpoolP512t1::one().neg()],
        );

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // BrainpoolP512t1 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<BrainpoolP512t1_Fq, BRAINPOOLP512t1_SCALAR_SLICES, BrainpoolP512t1>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BrainpoolP512t1_Fr = BrainpoolP512t1_Fr::derive_from_seed(seed);
        let scalar_field = BrainpoolP512t1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
