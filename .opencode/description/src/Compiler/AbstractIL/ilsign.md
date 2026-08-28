# ilsign.fs

**Purpose**
Implementation of strong-name signing for .NET assemblies. The `ILStrongNameSigner` type is a managed F# union (rather than a P/Invoke into `mscorwks`/`System.Security`) that supports: (a) delay-signing with a public key, (b) full delay-signing with the public-key-blob "use public key" option, (c) full signing with an in-memory private key pair (CAPI `PRIVATEKEYBLOB`), and (d) a key-container path that is explicitly unsupported on this platform. The signer hashes the assembly (all headers + sections, skipping the checksum and Authenticode signature blob and the strong-name signature blob), creates a SHA1/RSA signature (PKCS#1), and patches it into the PE image — including flipping the `CorFlags.StrongNameSigned` bit in `IMAGE_COR20_HEADER`.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.StrongNameSign`)

**Key bindings / helpers**
- `KeyType = Public | KeyPair` (discriminates raw CAPI blobs vs. key-pair blobs at parse time).
- CAPI constants: `ALG_TYPE_RSA`, `ALG_CLASS_KEY_EXCHANGE/SIGNATURE/HASH`, `CALG_RSA_KEYX`, `CALG_RSA_SIGN`, `CALG_SHA1`, `PUBLICKEYBLOB=0x6`, `PRIVATEKEYBLOB=0x7`, `BLOBHEADER_CURRENT_BVERSION=0x2`, `BLOBHEADER_LENGTH=20`, `RSA_PUB_MAGIC=0x31415352` ("RSA1"), `RSA_PRIV_MAGIC=0x32415352` ("RSA2").
- `getResourceString` — helper for `FSComp.SR`-based error messages.
- `ByteArrayUnion` (struct with explicit layout) — a `byte[]`/`ImmutableArray<byte>` union used to avoid copies when reading the PE image; `getUnderlyingArray`.
- `hashAssembly (peReader) (hashAlgorithm)` — compute the strong-name hash: append all PE headers (with checksum and security-directory zero-cleared), then each section (skipping the bytes covered by the strong-name signature directory). Returns the final digest via `IncrementalHash`.
- `BlobReader` (class) — little-endian reader over a CAPI key blob (`ReadInt32`, `ReadBigInteger`).
- `RSAParametersFromBlob (blob) (keyType)` — parse a CAPI public or private key blob into `RSAParameters` (validates `RSA1`/`RSA2` magic, bit length, field sizes).
- `validateRSAField` — enforce field lengths (Modulus/Exponent/P/Q/DP/DQ/InverseQ/D).
- `toCLRKeyBlob (rsaParameters: RSAParameters) (algId: int)` — serialize `RSAParameters` back to a CLR-format key blob (12-byte CLR header + BLOBHEADER + RSAPUBKEY + keys, little-endian).
- `createSignature (hash) (keyBlob) (keyType)` — `System.Security.Cryptography.RSA` sign (SHA1, PKCS#1); note the signature is reversed (CLR big-endian).
- `patchSignature (stream) (peReader) (signature)` — write the signature at the strong-name signature directory offset and set `CorFlags.StrongNameSigned` in `IMAGE_COR20_HEADER.Flags`.
- `signStream (stream) (keyBlob)` — orchestrate hash → sign → patch.
- `signatureSize (pk: byte[])` — infer the signature size from a public key blob (tries offset 8 for a raw key and offset 20 for a CLR-wrapped one).
- `getPublicKeyForKeyPair (kp: byte[]) : pubKey` — extract the public key from a CAPI private key pair.
- `isKeyPairBlob (blob)` — detect a raw CAPI `PRIVATEKEYBLOB`.
- Type aliases: `keyContainerName = string`, `keyPair = byte array`, `pubkey = byte array`, `pubkeyOptions = byte array * bool`.
- `signerGetPublicKeyForKeyPair`, `signerSignatureSize`, `signerSignStreamWithKeyPair`, `failWithContainerSigningUnsupportedOnThisPlatform`.

**TypeDefs**
- `ILStrongNameSigner` (sealed union, per `ilsign.fsi`) with cases `PublicKeySigner of pubkey`, `PublicKeyOptionsSigner of pubkeyOptions`, `KeyPair of keyPair`, `KeyContainer of keyContainerName`; static constructors `OpenPublicKeyOptions`, `OpenPublicKey`, `OpenKeyPairFile`, `OpenKeyContainer`; members `IsFullySigned`, `PublicKey`, `SignatureSize`, `SignStream: Stream -> unit`. Note: a `KeyPair` public-key lookup auto-extracts the public portion if the blob is a `PRIVATEKEYBLOB`, so private material is never embedded in the assembly.

**Significant internal logic**
- `StrongNameSigned` is set in the COR header flags only when a full signature is patched; `PublicKeySigner`/`PublicKeyOptionsSigner` only delay-sign (they set the public key in the manifest, no signature is written — see `ilwrite.fs`).
- The CAPI RSA blob format is implemented in pure F# (no P/Invoke): the same `BlobReader` is used for parsing and serializing keys.
- The `KeyContainer` path is not supported on this platform and raises — callers using a key container (e.g. a Windows CryptoAPI key) are not currently possible.

**Cross-references**
- `ilsign.fsi` (contract), `ilwrite.fsi` / `ilwrite.fs` (consumer: `options.signer`), `System.Security.Cryptography.RSA`, `System.Reflection.PortableExecutable.PEReader`, `FSharp.Compiler.Text` (error strings)
