# Hashing.fs

**Purpose**: Provides two small functional MD5-hashing modules used to build stable cache/version keys: `Md5StringHasher` folds data into a dash-stripped hex string (suitable as a cache key), and `Md5Hasher` folds data into raw byte arrays. Both support incremental "add" combinators over strings, bytes, booleans, integers, and dates.

**Namespace(s)**: `Internal.Utilities.Hashing`

**Modules declared**:
- `module internal Md5StringHasher`: hashing into a **string**. `hashString`, `empty` (`String.Empty`), `addBytes`/`addString`/`addSeq`/`addStrings`, `addBool`, `addDateTime`
- `module internal Md5Hasher`: hashing into a **byte array**. `computeHash`, `empty`, `hashString`, `addBytes`/`addString`/`addSeq`/`addStrings`/`addBytes'`, `addBool`, `addDateTime(s)`, `addInt(eger(s))`, `addBooleans`, `toString`

**Public API surface** (internal):
- Combinator pattern everywhere: `addX value rest -> newHash` (e.g. `addString s s2`, `addSeq items addItem s`), supporting `fold`-style construction of version keys
- `Md5StringHasher.addBytes` returns `BitConverter.ToString(hash).Replace("-","")` — flat lowercase-free hex without separators

**Significant internal logic**:
- Both modules keep a `ThreadLocal<MD5>` instance; however `Md5Hasher.computeHash` currently creates a fresh `MD5` per call with a TODO noting the ThreadLocal "is not working in new VS extension" (comment in source)
- MD5 here is used purely for **canonic hashing** of cache/version keys (strings, timestamps, flags), not security
- `addDateTime` folds in `dt.Ticks`; `addInt` folds in `BitConverter.GetBytes i`
- Commented-out `addVersions` shows intended use over `ICacheKey` sequences

**Cross-references**: Works with AsyncMemoize (`ICacheKey` version strings), LruCache versioning, and the service layer's cache-key/version computation.
