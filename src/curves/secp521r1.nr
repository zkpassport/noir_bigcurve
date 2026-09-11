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
            0xa5fc52b01680d5f31f189d5b6b5a3e,
            0x4911786cc8c1f97108edf1ac91fb0e,
            0xfedb98c51e459281c6d5b0a9e3803b,
            0x99f948b8a45043f75922859d37d371,
            0x018019b5cd78,
        ]),
        Secp521r1_Fq::from_limbs([
            0x6f28e24eafb1c9aaf7cbe2406b142a,
            0x57857c4e6fea3f00e6dc2f7ba17e19,
            0xbad88c81f8341e12c62ab0d116aad4,
            0xecc24573e5a9a2ddb13b2eb95c62a9,
            0x018268d0777c,
        ]),
    ],
    offset_generator_final: [
        Secp521r1_Fq::from_limbs([
            0x2f53be3ebf94127aa4285b155929da,
            0xdd820aa0815962735e33c5b570a63a,
            0xca8c5a15747da4362e2c4fbb211bab,
            0x411deec434aa6a170ed1079b8fb4e9,
            0x01e8433b7e6b,
        ]),
        Secp521r1_Fq::from_limbs([
            0x2137b9d8d6d8a7a47d757da0d99c2f,
            0x4585b5f6ef998c49fb885d22f028c7,
            0x72b55e824932810bb70186b60705c7,
            0x9bf74c7588259d29af8df6c5c03e18,
            0x01cc2ae7a882,
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
