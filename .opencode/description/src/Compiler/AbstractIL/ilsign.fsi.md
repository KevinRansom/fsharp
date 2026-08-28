# ilsign.fsi

**Purpose**
Interface contract for the strong-name signer (`ILStrongNameSigner`) used by the IL writer. A sealed type with two static-open constructors (`OpenPublicKeyOptions` with a "use public key to sign" flag; `OpenPublicKey` for delay-sign), plus `OpenKeyPairFile` and `OpenKeyContainer` (key container is not supported on this platform — see `ilsign.fs` implementation). The signer exposes the public key, the signature size, and the `SignStream` operation.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.StrongNameSign`)

**TypeDefs declared**
- `ILStrongNameSigner` (sealed class, per `ilsign.fsi`), with:
  - `member PublicKey: byte array`
  - `static member OpenPublicKeyOptions (bytes: byte array) (bool: bool) : ILStrongNameSigner`
  - `static member OpenPublicKey (bytes: byte array) : ILStrongNameSigner`
  - `static member OpenKeyPairFile (bytes: byte array) : ILStrongNameSigner`
  - `static member OpenKeyContainer (string: string) : ILStrongNameSigner`
  - `member IsFullySigned: bool` — `true` only for a full (private-key) signer.
  - `member PublicKey: byte array` (re-declared in the contract — see `ilsign.fs`)
  - `member SignatureSize: int`
  - `member SignStream: System.IO.Stream -> unit`

**Cross-references**
- `ilsign.fs` (implementation), `ilwrite.fsi` / `ilwrite.fs` (consumer: `options.signer`)
