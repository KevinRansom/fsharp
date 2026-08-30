# ilsign.fs

## Pipeline role

Part of the AbstractIL layer. This module implements strong-name (RSA) signing of .NET assemblies, replacing the native CLR strong-name APIs: parsing CAPI `PUBLICKEYBLOB`/`PRIVATEKEYBLOB` blobs into `RSAParameters`, converting `RSAParameters` back into a CLR-format key blob, computing the signed hash over a PE file (skipping checksum, Authenticode, and the strong-name signature area), computing RSA signatures, and patching the signature blob + `StrongNameSigned` flag back into the stream. It also hosts the `ILStrongNameSigner` abstraction consumed by the driver.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.StrongNameSign` (module `internal`, `#nowarn "9"`)
- Uses: `System`, `System.IO`, `System.Collections.Immutable`, `System.Reflection.PortableExecutable` (`PEReader`, `PEHeaders`, `PEMagic`, `CorFlags`), `System.Security.Cryptography`, `System.Runtime.InteropServices`, `FSharp.Compiler.Text` (`RichText`), `Internal.Utilities.Library`.

## Types

- `KeyType` (DU) — `Public | KeyPair`; distinguishes public-only blobs from full key pairs.
- `ByteArrayUnion` (`[<Struct; StructLayout(LayoutKind.Explicit)>]`) — a reinterpretation union over the same 8 bytes exposing either a `byte array` (`FieldOffset(0)`) or an `ImmutableArray<byte>` (`FieldOffset(0)`); used to extract the underlying array of the entire PE image without copying.
- `BlobReader` (class) — minimal reader over a byte array with `_blob` and `_offset`:
  - `ReadInt32()` — little-endian 4-byte read.
  - `ReadBigInteger(length)` — copies `length` bytes and reverses (CAPI stores big-endian integers).
- `ILStrongNameSigner` (DU) — the signer abstraction:
  - `PublicKeySigner of pubkey | PublicKeyOptionsSigner of pubkeyOptions | KeyPair of keyPair | KeyContainer of keyContainerName`.
  - Static factories: `OpenPublicKeyOptions kp p`, `OpenPublicKey bytes`, `OpenKeyPairFile bytes`, `OpenKeyContainer s`.
  - `IsFullySigned` — true for `KeyPair`, true for `PublicKeyOptionsSigner` when public-sign is enabled, false for `PublicKeySigner`.
  - `PublicKey` — the public key blob; for `KeyPair`/full key pair blobs extracts the public key via `signerGetPublicKeyForKeyPair` (so private key material is never embedded in the assembly).
  - `SignatureSize` — derives the signature size (defaults `0x80` if `StrongNameSignatureSize` fails).
  - `SignStream stream` — signs for `KeyPair`; no-op for public-only signers.
- Type abbreviations: `keyContainerName = string`, `keyPair = byte array`, `pubkey = byte array`, `pubkeyOptions = byte array * bool`.

## Constants

- ALG constants: `ALG_TYPE_RSA = 2 <<< 9`, `ALG_CLASS_KEY_EXCHANGE = 5 <<< 13`, `ALG_CLASS_SIGNATURE = 1 <<< 13`, `CALG_RSA_KEYX`, `CALG_RSA_SIGN`, `ALG_CLASS_HASH = 4 <<< 13`, `ALG_TYPE_ANY = 0`, `CALG_SHA1`.
- Blob constants: `PUBLICKEYBLOB = 0x6`, `PRIVATEKEYBLOB = 0x7`, `BLOBHEADER_CURRENT_BVERSION = 0x2`, `BLOBHEADER_LENGTH = 20`, `RSA_PUB_MAGIC = 0x31415352` ("RSA1"), `RSA_PRIV_MAGIC = 0x32415352` ("RSA2").

## Functions

- `getResourceString (_, message: RichText)` — extracts text from resource messages.
- `getUnderlyingArray (array: ImmutableArray<byte>)` — via `ByteArrayUnion`.
- `hashAssembly (peReader: PEReader) (hashAlgorithm: IncrementalHash) : byte[]` — hashes the static content of an assembly:
  - Hashes all headers (DOS/PE/optional header + COFF + section headers), clearing the Checksum field (`peHeaderOffset + 0x40`) and the security directory data-directory entry (offsets differ for PE32 `+0x80`/size `0xE0` vs PE32+ `+0x90`/`0xF0`).
  - Hashes each section, slicing around the strong-name signature blob (which must lie within one section, else `BadImageFormatException`).
  - Returns `hashAlgorithm.GetHashAndReset()`.
- `RSAParametersFromBlob blob keyType` — parses a CAPI blob: validates blob magic (`0x00000207` for key pairs) and `RSA_PRIV_MAGIC`, computes `byteLen`/`halfLen` from bit length (must be a multiple of 16), then reads Exponent, Modulus, P, Q, DP, DQ, InverseQ, D (all reversed big-endian).
- `validateRSAField field expected name` — checks a private-key CRT field length.
- `toCLRKeyBlob (rsaParameters: RSAParameters) (algId: int) : byte array` — serializes RSA parameters into the CLR key blob format:
  - Requires `algId = CALG_RSA_KEYX` (only this one is ported).
  - Writes the CLR header (aiKeyAlg `CALG_RSA_SIGN`, aiHashAlg `CALG_SHA1`, KeyLength), the BLOBHEADER (bType PUBLIC/PRIVATE based on presence of CRT fields, bVersion 2, aiKeyAlg), the RSAPubKey header (magic RSA2/RSA1, bitLen), the exponent as a dword, then the reversed modulus and (for private keys) P, Q, DP, DQ, InverseQ, D.
- `createSignature (hash: byte array) keyBlob keyType` — imports RSA parameters and produces a PKCS#1-SHA1 signature, reversed (strong-name signatures are little-endian byte reversed).
- `patchSignature (stream: Stream) (peReader: PEReader) (signature: byte array)` — see ks the strong-name directory offset (validating size), writes the signature bytes, then sets the `StrongNameSigned` COR20 flag by writing to `CorHeaderStartOffset + 16` (IMAGE_COR20_HEADER.Flags).
- `signStream stream keyBlob` — the top-level sign flow: open `PEReader` over the stream (PrefetchEntireImage + LeaveOpen), hash with SHA1 via `hashAssembly`, `createSignature`, `patchSignature`.
- `signatureSize (pk: byte array)` — determines the RSA key size (and hence signature size) by scanning for the RSAPubKey magic (`RSA_PUB_MAGIC`/`RSA_PRIV_MAGIC`) at offsets 8 (raw blob) or 20 (CLR blob with 12-byte CLR header + 8-byte BLOBHEADER) and returning bitLen/8.
- `getPublicKeyForKeyPair keyBlob` — imports the key pair and exports only the public parameters as a CLR key blob.
- `isKeyPairBlob (blob)` — true when `blob[0] = PRIVATEKEYBLOB` and `blob[1] = BLOBHEADER_CURRENT_BVERSION`.
- `signerGetPublicKeyForKeyPair`, `signerSignatureSize`, `signerSignStreamWithKeyPair` — the signer hooks.
- `failWithContainerSigningUnsupportedOnThisPlatform ()` — throws for key-container signing (unsupported on this platform).

## Significant internal logic

- Hashing mirrors the CLR's `HashAssembly`: skip the checksum, the Authenticode security directory entry, and the strong-name signature blob itself, and treat the two-bit magic/format variants (PE32 vs PE32+) separately.
- All multi-byte key material is stored big-endian in blobs, hence `Array.rev` on read (in `ReadBigInteger`) and write (the `safeArrayRev` helper).
- The `ByteArrayUnion` trick lets the entire PE image be hashed without an explicit copy by reinterpreting `ImmutableArray<byte>` as a raw byte array.