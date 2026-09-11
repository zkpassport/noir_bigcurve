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
            0xb2a18a1b76317233dbce6ca69dda29,
            0x5b6dd810bafe6337eb57131957bfd5,
            0x0a3d,
        ]),
        BrainpoolP256r1_Fq::from_limbs([
            0xa6431ef41460120e77d1244f6a359d,
            0x11b64140abb4a362107e18403f72cf,
            0x77d0,
        ]),
    ],
    offset_generator_final: [
        BrainpoolP256r1_Fq::from_limbs([
            0xcf6ee4eaf53b9635fd9354a95fc13b,
            0x0ad036f490ae2ab57695484b175d67,
            0x3ee3,
        ]),
        BrainpoolP256r1_Fq::from_limbs([
            0xcd1b62a6e1d068fca8c6b43707f0ab,
            0x22d71b05c0c1f36b90699f883a0a82,
            0x1783,
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
