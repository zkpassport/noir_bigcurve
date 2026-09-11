use bignum::BigNum;
pub use bignum::{BrainpoolP256t1_Fq, BrainpoolP256t1_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global BRAINPOOLP256t1_PARAM: BigCurveParams<BrainpoolP256t1_Fq> = BigCurveParams {
    a: BrainpoolP256t1_Fq::from_limbs([
        0x3bf623d52620282013481d1f6e5374,
        0x57dba1eea9bc3e660a909d838d726e,
        0xa9fb,
    ]),
    b: BrainpoolP256t1_Fq::from_limbs([
        0x93ebc4af2f49256ae58101fee92b04,
        0x61c430d84ea4fe66a7733d0b76b7bf,
        0x662c,
    ]),
    one: [
        BrainpoolP256t1_Fq::from_limbs([
            0xa142c47aafbc2b79a191562e1305f4,
            0xeb3cc1cfe7b7732213b23a656149af,
            0xa3e8,
        ]),
        BrainpoolP256t1_Fq::from_limbs([
            0xbcb6de39d027001dabe8f35b25c9be,
            0x6c823439c56d7f7b22e14644417e69,
            0x2d99,
        ]),
    ],
    offset_generator: [
        BrainpoolP256t1_Fq::from_limbs([
            0x2fff6a6ef2915991612b4909104b15,
            0xbfd4494ef86cd7bf260d1a402708a0,
            0xa74f,
        ]),
        BrainpoolP256t1_Fq::from_limbs([
            0x4d84903113e007ba2368a7b0cca905,
            0xe13c3062a49e63d9d5da825e0304d2,
            0x7d46,
        ]),
    ],
    offset_generator_final: [
        BrainpoolP256t1_Fq::from_limbs([
            0x0d517406dc168028a87f60fc3a4946,
            0xd7ad7be411092513b7539d90ac7f60,
            0x6618,
        ]),
        BrainpoolP256t1_Fq::from_limbs([
            0x58dc18df646a83d3d672755cb95f96,
            0xa35754138364d1ed3be85d1c5a0c2c,
            0x72dc,
        ]),
    ],
};

pub global BRAINPOOLP256t1_SCALAR_SLICES: u32 = 65;
pub type BrainpoolP256t1Scalar = ScalarField<BRAINPOOLP256t1_SCALAR_SLICES>;

#[derive_curve_impl(quote { bignum::BrainpoolP256t1_Fq }, quote { BRAINPOOLP256t1_PARAM })]
pub struct BrainpoolP256t1 {
    pub x: BrainpoolP256t1_Fq,
    pub y: BrainpoolP256t1_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, BrainpoolP256t1_Fq, BrainpoolP256t1_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{BrainpoolP256t1, BRAINPOOLP256t1_SCALAR_SLICES, BrainpoolP256t1Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = BrainpoolP256t1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP256t1_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = BrainpoolP256t1::one();
        let negone = BrainpoolP256t1_Fr::one().neg();
        let scalar = BrainpoolP256t1Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = BrainpoolP256t1::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = BrainpoolP256t1_Fr::from(4);
        let p_minus_4_fr = BrainpoolP256t1_Fr::modulus() - four;
        let p_minus_4 = BrainpoolP256t1Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BrainpoolP256t1_Fr::one();
        let p_minus_5 = BrainpoolP256t1Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = BrainpoolP256t1::one();
        let b = a.neg();
        let points = [a, b];

        let result = BrainpoolP256t1::evaluate_linear_expression(
            points,
            scalars,
            [BrainpoolP256t1::one().neg()],
        );

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // BrainpoolP256t1 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<BrainpoolP256t1_Fq, BRAINPOOLP256t1_SCALAR_SLICES, BrainpoolP256t1>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BrainpoolP256t1_Fr = BrainpoolP256t1_Fr::derive_from_seed(seed);
        let scalar_field = BrainpoolP256t1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
