# Hardy
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

type
  BaseUint* = SomeUnsignedInt or byte

  HardBase*[T: BaseUint] = distinct T

  HardBool*[T: HardBase] = range[T(0)..T(1)]
    ## To avoid the compiler replacing bitwise boolean operations
    ## by conditional branches, we don't use booleans.
    ## We use an int to prevent compiler "optimization" and introduction of branches

  Hard*[T: HardBase] = distinct openarray[T]
    ## Hardy primitives are memory-backend agnostic.
    ## Hardy integers can be stored in an opaque stack array
    ## or a seq or even a string.
    ##
    ## Allocations is left to the client library.
    ## Note that constant-time allocation is very involved for
    ## heap-allocated types (i.e. requires a memory pool)

func htrue*(T: type(BaseUint)): auto {.compileTime.}=
  (HardBool[HardBase[T]])(true)

func hfalse*(T: type(BaseUint)): auto {.compileTime.}=
  (HardBool[HardBase[T]])(false)

template hard*(x: static int, T: type BaseUint): HardBase[T] =
  ## For int literals
  (HardBase[T])(x)

template hard*(x: BaseUint): HardBase[type x] =
  (HardBase[T])(x)
