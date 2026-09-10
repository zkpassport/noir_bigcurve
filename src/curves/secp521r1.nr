use bignum::BigNum;
pub use bignum::{Secp521r1_Fq, Secp521r1_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global SECP521r1_PARAM: BigCurveParams<Secp521r1_Fq> = BigCurveParams {
    a: Secp521r1_Fq::from_limbs([
        0xfffffffffffffffffffffffffffffc,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x01ffffffffff,
    ]),
    b: Secp521r1_Fq::from_limbs([
        0x73df883d2c34f1ef451fd46b503f00,
        0x3951ec7e937b1652c0bd3bb1bf0735,
        0x5b99b315f3b8b489918ef109e15619,
        0x8e1c9a1f929a21a0b68540eea2da72,
        0x51953eb961,
    ]),
    one: [
        Secp521r1_Fq::from_limbs([
            0x48b3c1856a429bf97e7e31c2e5bd66,
            0x5e77efe75928fe1dc127a2ffa8de33,
            0x39053fb521f828af606b4d3dbaa14b,
            0x0404e9cd9e3ecb662395b4429c6481,
            0xc6858e06b7,
        ]),
        Secp521r1_Fq::from_limbs([
            0x3c7086a272c24088be94769fd16650,
            0x72995ef42640c550b9013fad076135,
            0x49579b446817afbd17273e662c97ee,
            0x9a3bc0045c8a5fb42c7d1bd998f544,
            0x011839296a78,
        ]),
    ],
    offset_generator: [
        Secp521r1_Fq::from_limbs([
            0x33601ec928a49428bd42bfd3e617a5,
            0xf7893350b9f5675365ff188b60a88f,
            0x50c21d3f20da3b152d35ab8cd4c232,
            0x6fad54e41d6c7f2401aadff545a0c0,
            0x0179ea30209a,
        ]),
        Secp521r1_Fq::from_limbs([
            0x62b1ee3215a9e0f6716d3246df80cc,
            0x141a855a1eb15473d679aa7e6639bb,
            0x353f28185fafbcfac08d8a542676d6,
            0x2ca698111831b8f871e158b6ac75,
            0x0113caf1fcb8,
        ]),
    ],
    offset_generator_final: [
        Secp521r1_Fq::from_limbs([
            0xebdc2655240109f6049d0dce09d015,
            0x96e62cabb84212e4895a786c77c13e,
            0xdb1aea5b997aaaebfb77697740cac8,
            0x02e23bb06c5ceb3496ea4c111fa08b,
            0x2f484c4190,
        ]),
        Secp521r1_Fq::from_limbs([
            0x30dcd5187b8a391d3303ec43936bd6,
            0xba8713179618a4f38f95d8a1fe2f23,
            0x6ffda93a5b220f1c880b38e84be4d8,
            0x7201361e3c650d985689ce9940fd03,
            0x09e8754f07,
        ]),
    ],
};

pub global SECP521r1_SCALAR_SLICES: u32 = 131;
pub type Secp521r1Scalar = ScalarField<SECP521r1_SCALAR_SLICES>;

#[derive_curve_impl(quote { bignum::Secp521r1_Fq }, quote { SECP521r1_PARAM })]
pub struct Secp521r1 {
    pub x: Secp521r1_Fq,
    pub y: Secp521r1_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, Secp521r1_Fq, Secp521r1_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{Secp521r1, SECP521r1_SCALAR_SLICES, Secp521r1Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = Secp521r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == SECP521r1_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = Secp521r1::one();
        let negone = Secp521r1_Fr::one().neg();
        let scalar = Secp521r1Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = Secp521r1::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = Secp521r1_Fr::from(4);
        let p_minus_4_fr = Secp521r1_Fr::modulus() - four;
        let p_minus_4 = Secp521r1Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - Secp521r1_Fr::one();
        let p_minus_5 = Secp521r1Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = Secp521r1::one();
        let b = a.neg();
        let points = [a, b];

        let result =
            Secp521r1::evaluate_linear_expression(points, scalars, [Secp521r1::one().neg()]);

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // Secp521r1 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<Secp521r1_Fq, SECP521r1_SCALAR_SLICES, Secp521r1>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: Secp521r1_Fr = Secp521r1_Fr::derive_from_seed(seed);
        let scalar_field = Secp521r1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
