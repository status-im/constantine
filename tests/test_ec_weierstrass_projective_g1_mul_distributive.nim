# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  # Standard library
  std/[unittest, times],
  # Internals
  ../constantine/config/[common, curves],
  ../constantine/arithmetic,
  ../constantine/io/io_bigints,
  ../constantine/elliptic/[ec_weierstrass_affine, ec_weierstrass_projective, ec_scalar_mul],
  # Test utilities
  ../helpers/prng_unsafe,
  ./support/ec_reference_scalar_mult,
  ./test_ec_template

const
  Iters = 128
  ItersMul = Iters div 4

run_EC_mul_distributive_tests(
    ec = ECP_SWei_Proj[Fp[BN254_Snarks]],
    ItersMul = ItersMul,
    moduleName = "test_ec_weierstrass_projective_g1_mul_distributive_" & $BN254_Snarks
  )

run_EC_mul_distributive_tests(
    ec = ECP_SWei_Proj[Fp[BLS12_381]],
    ItersMul = ItersMul,
    moduleName = "test_ec_weierstrass_projective_g1_mul_distributive_" & $BLS12_381
  )