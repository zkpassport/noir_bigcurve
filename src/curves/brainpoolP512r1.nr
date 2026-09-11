use bignum::BigNum;
pub use bignum::{BrainpoolP512r1_Fq, BrainpoolP512r1_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global BRAINPOOLP512r1_PARAM: BigCurveParams<BrainpoolP512r1_Fq> = BigCurveParams {
    a: BrainpoolP512r1_Fq::from_limbs([
        0x1117a72bf2c7b9e7c1ac4d77fc94ca,
        0x5d5aa8253aa10a2ef1c98b9ac8b57f,
        0x8d3df91610a83441caea9863bc2ded,
        0x8b603b89e2327145ac234cc594cbdd,
        0x7830a331,
    ]),
    b: BrainpoolP512r1_Fq::from_limbs([
        0x4050b75ebae5dd2809bd638016f723,
        0xc7b9e7c1ac4d77fc94cadc083e6798,
        0xa10a2ef1c98b9ac8b57f1117a72bf2,
        0xa83441caea9863bc2ded5d5aa8253a,
        0x3df91610,
    ]),
    one: [
        BrainpoolP512r1_Fq::from_limbs([
            0x6d5047406a5e688b352209bcb9f822,
            0x1f78e2d0d48d50d1687b93b97d5f7c,
            0x70b5d916c1b43b62eef4d0098eff3b,
            0xd82ed9645a21322e9c4c6a9385ed9f,
            0x81aee4bd,
        ]),
        BrainpoolP512r1_Fq::from_limbs([
            0xca2b2fa8f0540678cd1e0f3ad80892,
            0xde494a5f485e5bca4bd88a2763aed1,
            0x24a57b1aa000c55b881f8111b2dc,
            0x566332ecc0eabfa9cf7822fdf209f7,
            0x7dde385d,
        ]),
    ],
    offset_generator: [
        BrainpoolP512r1_Fq::from_limbs([
            0x4ccca520946e1106be85f69c0a4813,
            0x17be3b58f9be2e19a1696de291be01,
            0x92f0c082d07ac5f34515e889d94867,
            0x72c9ab5e0b5bd46a0ec2b309f026a5,
            0x446a8b9e,
        ]),
        BrainpoolP512r1_Fq::from_limbs([
            0x02695eb448a415ca4267a53a72c38f,
            0x4df2b0d7d995f88d99b0234206aa21,
            0x1ae69e2ee3a6816104d311eda865d4,
            0x5e293aae1b2b2cd9cd7b15ef48bed4,
            0x3b7f4743,
        ]),
    ],
    offset_generator_final: [
        BrainpoolP512r1_Fq::from_limbs([
            0x9e1d8da946b70c27bac240ba20b103,
            0x05af8d5eab13765ea06a10a91a3f73,
            0x2891234ae6575ae515588edb937a1b,
            0x2803943058d1854bbe5b600ba63d3d,
            0x46534c7d,
        ]),
        BrainpoolP512r1_Fq::from_limbs([
            0x17ed7dbf8c7e40214cf9a89d52cedd,
            0x0fa1f2b5c10f5a2781a6476f755e79,
            0x5118303a788512a741ed2e1e8d7c54,
            0x26c30383955818df940e7a8d62fa6a,
            0x1cfc4893,
        ]),
    ],
};

pub global BRAINPOOLP512r1_SCALAR_SLICES: u32 = 129;
pub type BrainpoolP512r1Scalar = ScalarField<BRAINPOOLP512r1_SCALAR_SLICES>;

#[derive_curve_impl(quote { bignum::BrainpoolP512r1_Fq }, quote { BRAINPOOLP512r1_PARAM })]
pub struct BrainpoolP512r1 {
    pub x: BrainpoolP512r1_Fq,
    pub y: BrainpoolP512r1_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, BrainpoolP512r1_Fq, BrainpoolP512r1_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{BrainpoolP512r1, BRAINPOOLP512r1_SCALAR_SLICES, BrainpoolP512r1Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = BrainpoolP512r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP512r1_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = BrainpoolP512r1::one();
        let negone = BrainpoolP512r1_Fr::one().neg();
        let scalar = BrainpoolP512r1Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = BrainpoolP512r1::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = BrainpoolP512r1_Fr::from(4);
        let p_minus_4_fr = BrainpoolP512r1_Fr::modulus() - four;
        let p_minus_4 = BrainpoolP512r1Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BrainpoolP512r1_Fr::one();
        let p_minus_5 = BrainpoolP512r1Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = BrainpoolP512r1::one();
        let b = a.neg();
        let points = [a, b];

        let result = BrainpoolP512r1::evaluate_linear_expression(
            points,
            scalars,
            [BrainpoolP512r1::one().neg()],
        );

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // BrainpoolP512r1 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<BrainpoolP512r1_Fq, BRAINPOOLP512r1_SCALAR_SLICES, BrainpoolP512r1>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BrainpoolP512r1_Fr = BrainpoolP512r1_Fr::derive_from_seed(seed);
        let scalar_field = BrainpoolP512r1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
