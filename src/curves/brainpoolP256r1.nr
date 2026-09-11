use bignum::BigNum;
pub use bignum::{BrainpoolP256r1_Fq, BrainpoolP256r1_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global BRAINPOOLP256r1_PARAM: BigCurveParams<BrainpoolP256r1_Fq> = BigCurveParams {
    a: BrainpoolP256r1_Fq::from_limbs([
        0x8055c126dc5c6ce94a4b44f330b5d9,
        0x0975fc2c3057eef67530417affe7fb,
        0x7d5a,
    ]),
    b: BrainpoolP256r1_Fq::from_limbs([
        0x8416295cf7e1ce6bccdc18ff8c07b6,
        0x5c6ce94a4b44f330b5d9bbd77cbf95,
        0x26dc,
    ]),
    one: [
        BrainpoolP256r1_Fq::from_limbs([
            0xde27e1e3bd23c23a4453bd9ace3262,
            0xaeb9cb7e57cb2c4b482ffc81b7afb9,
            0x8bd2,
        ]),
        BrainpoolP256r1_Fq::from_limbs([
            0x7745132ded8e545c1d54c72f046997,
            0xf835c3dac4fd97f8461a14611dc9c2,
            0x547e,
        ]),
    ],
    offset_generator: [
        BrainpoolP256r1_Fq::from_limbs([
            0x2fff6a6ef2915991612b4909104b15,
            0xbfd4494ef86cd7bf260d1a402708a0,
            0xa74f,
        ]),
        BrainpoolP256r1_Fq::from_limbs([
            0x3e096aac7583716de36fd796f4177f,
            0x3aa63e235b213f416539e3c68a92a6,
            0x38fc,
        ]),
    ],
    offset_generator_final: [
        BrainpoolP256r1_Fq::from_limbs([
            0x37f51e0f570c65419f8eff21c70eba,
            0x44d6d5f4d580a7ee1fe9122557ad60,
            0x3c63,
        ]),
        BrainpoolP256r1_Fq::from_limbs([
            0xe1fbc0a3edec9f54d91ef268d56630,
            0xd98545f8c16bafb3b176c0dbf5a8b7,
            0x6ce3,
        ]),
    ],
};

pub global BRAINPOOLP256r1_SCALAR_SLICES: u32 = 65;
pub type BrainpoolP256r1Scalar = ScalarField<BRAINPOOLP256r1_SCALAR_SLICES>;

#[derive_curve_impl(quote { bignum::BrainpoolP256r1_Fq }, quote { BRAINPOOLP256r1_PARAM })]
pub struct BrainpoolP256r1 {
    pub x: BrainpoolP256r1_Fq,
    pub y: BrainpoolP256r1_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, BrainpoolP256r1_Fq, BrainpoolP256r1_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{BrainpoolP256r1, BRAINPOOLP256r1_SCALAR_SLICES, BrainpoolP256r1Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = BrainpoolP256r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP256r1_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = BrainpoolP256r1::one();
        let negone = BrainpoolP256r1_Fr::one().neg();
        let scalar = BrainpoolP256r1Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = BrainpoolP256r1::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = BrainpoolP256r1_Fr::from(4);
        let p_minus_4_fr = BrainpoolP256r1_Fr::modulus() - four;
        let p_minus_4 = BrainpoolP256r1Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BrainpoolP256r1_Fr::one();
        let p_minus_5 = BrainpoolP256r1Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = BrainpoolP256r1::one();
        let b = a.neg();
        let points = [a, b];

        let result = BrainpoolP256r1::evaluate_linear_expression(
            points,
            scalars,
            [BrainpoolP256r1::one().neg()],
        );

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // BrainpoolP256r1 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<BrainpoolP256r1_Fq, BRAINPOOLP256r1_SCALAR_SLICES, BrainpoolP256r1>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BrainpoolP256r1_Fr = BrainpoolP256r1_Fr::derive_from_seed(seed);
        let scalar_field = BrainpoolP256r1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
