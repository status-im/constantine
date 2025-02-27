import
  # Internals
  ../constantine/hashes,
  ../constantine/platforms/codecs,
  # Helpers
  ../helpers/prng_unsafe

# Deal with platform mess
# --------------------------------------------------------------------
when defined(windows):
  when sizeof(int) == 8:
    const DLLSSLName* = "(libssl-1_1-x64|ssleay64|libssl64).dll"
  else:
    const DLLSSLName* = "(libssl-1_1|ssleay32|libssl32).dll"
else:
  when defined(macosx):
    const versions = "(.1.1|.38|.39|.41|.43|.44|.45|.46|.47|.48|.10|.1.0.2|.1.0.1|.1.0.0|.0.9.9|.0.9.8|)"
  else:
    const versions = "(.1.1|.1.0.2|.1.0.1|.1.0.0|.0.9.9|.0.9.8|.48|.47|.46|.45|.44|.43|.41|.39|.38|.10|)"

  when defined(macosx):
    const DLLSSLName* = "libssl" & versions & ".dylib"
  elif defined(genode):
    const DLLSSLName* = "libssl.lib.so"
  else:
    const DLLSSLName* = "libssl.so" & versions

# OpenSSL wrapper
# --------------------------------------------------------------------

# OpenSSL removed direct use of their SHA256 function. https://github.com/openssl/openssl/commit/4d49b68504cc494e552bce8e0b82ec8b501d5abe
# It isn't accessible anymore in Windows CI on Github Action.
# But the new API isn't expose on Linux :/

# TODO: fix Windows
when not defined(windows):
  proc SHA256[T: byte|char](
        msg: openarray[T],
        digest: ptr array[32, byte] = nil
      ): ptr array[32, byte] {.cdecl, dynlib: DLLSSLName, importc.}

  # proc EVP_Q_digest[T: byte|char](
  #                 ossl_libctx: pointer,
  #                 algoName: cstring,
  #                 propq: cstring,
  #                 data: openArray[T],
  #                 digest: var array[32, byte],
  #                 size: ptr uint): int32 {.cdecl, dynlib: DLLSSLName, importc.}

  proc SHA256_OpenSSL[T: byte|char](
        digest: var array[32, byte],
        s: openArray[T]) =
    discard SHA256(s, digest.addr)
    # discard EVP_Q_digest(nil, "SHA256", nil, s, digest, nil)

# Test
# --------------------------------------------------------------------

echo "\n------------------------------------------------------\n"
const SmallSizeIters = 64
const LargeSizeIters =  1

proc sanityABC =
  var bufCt: array[32, byte]
  let msg = "abc"

  let hashed = array[32, byte].fromHex(
    "BA7816BF8F01CFEA414140DE5DAE2223" &
    "B00361A396177A9CB410FF61F20015AD")

  sha256.hash(bufCt, msg)

  doAssert bufCt == hashed

proc sanityABC2 =
  var bufCt: array[32, byte]
  let msg = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"

  let hashed = array[32, byte].fromHex(
    "248D6A61D20638B8E5C026930C3E6039" &
    "A33CE45964FF2167F6ECEDD419DB06C1")

  sha256.hash(bufCt, msg)

  doAssert bufCt == hashed

when not defined(windows):
  proc innerTest(rng: var RngState, sizeRange: Slice[int]) =
    let size = rng.random_unsafe(sizeRange)
    let msg = rng.random_byte_seq(size)

    var bufCt, bufOssl: array[32, byte]

    sha256.hash(bufCt, msg)
    SHA256_OpenSSL(bufOssl, msg)
    doAssert bufCt == bufOssl, "Test failed with message of length " & $size

proc chunkTest(rng: var RngState, sizeRange: Slice[int]) =
  let size = rng.random_unsafe(sizeRange)
  let msg = rng.random_byte_seq(size)

  let chunkSize = rng.random_unsafe(2 ..< 20)

  var bufOnePass: array[32, byte]
  sha256.hash(bufOnePass, msg)

  var bufChunked: array[32, byte]
  let maxChunk = max(2, sizeRange.b div 10) # Consume up to 10% at once

  var ctx: Sha256Context
  ctx.init()
  var cur = 0
  while size - cur > 0:
    let chunkSize = rng.random_unsafe(0 ..< maxChunk)
    let stop = min(cur+chunkSize-1, size-1)
    let consumed = stop-cur+1
    ctx.update(msg.toOpenArray(cur, stop))
    cur += consumed

  ctx.finish(bufChunked)

  doAssert bufOnePass == bufChunked

proc main() =
  echo "SHA256 - sanity checks"
  sanityABC()
  sanityABC2()

  echo "SHA256 - Starting differential testing vs OpenSSL"

  var rng: RngState
  rng.seed(0xFACADE)

  when not defined(windows):
    echo "SHA256 - 0 <= size < 64 - exhaustive"
    for i in 0 ..< 64:
      rng.innerTest(i .. i)
  else:
    echo "SHA256 - 0 <= size < 64 - exhaustive [SKIPPED]"

  echo "SHA256 - 0 <= size < 64 - exhaustive chunked"
  for i in 0 ..< 64:
    rng.chunkTest(i .. i)

  echo "SHA256 - 64 <= size < 1024B - chunked"
  for _ in 0 ..< SmallSizeIters:
    rng.chunkTest(0 ..< 1024)

  when not defined(windows):
    echo "SHA256 - 64 <= size < 1024B"
    for _ in 0 ..< SmallSizeIters:
      rng.innerTest(0 ..< 1024)

    echo "SHA256 - 1MB <= size < 50MB"
    for _ in 0 ..< LargeSizeIters:
      rng.innerTest(1_000_000 ..< 50_000_000)

    echo "SHA256 - Differential testing vs OpenSSL - SUCCESS"

  else:
    echo "SHA256 - Differential testing vs OpenSSL - [SKIPPED]"

main()
