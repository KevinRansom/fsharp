# Hashing.fsi

**Purpose**: The contract for `Hashing.fs`: declares the two internal MD5-hashing modules and their "add" combinator set, one hashing to strings and one to byte arrays, for building cache/version keys.

**Namespace(s)**: `Internal.Utilities.Hashing`

**Modules declared**:
- `module internal Md5StringHasher`: `hashString: string -> byte array`, `empty: string`, `addBytes: byte array * string -> string`, `addString: string * string -> string`, `addSeq: 'item seq * ('item -> string -> string) -> string -> string`, `addStrings: string seq -> (string -> string)`, `addBool: bool * string -> string`, `addDateTime: DateTime * string -> string`
- `module internal Md5Hasher`: `computeHash: byte array -> byte array`, `empty: 'a array`, `hashString: string -> byte array`, `addBytes/addString/addSeq/addStrings/addBytes'/addBool/addDateTime/addDateTimes/addIntegers/addBooleans` (byte-array variants), `toString: byte array -> string`

**Contract notes**:
- The `addX` functions are curried fold helpers: given a value and a current hash, produce the next hash — e.g. `items |> Seq.fold (fun h item -> addItem item h) startHash`
- All `internal`; nothing here is part of the public Service API

**Cross-references**: Implements Hashing.fs; consumed by AsyncMemoize-style cache versions and service-layer key/version hashing.
