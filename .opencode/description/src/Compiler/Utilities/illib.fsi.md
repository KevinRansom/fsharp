# illib.fsi

**Purpose**: Signature file for `illib.fs` (same directory, namespace `Internal.Utilities.Library` — the compiler's pervasive internal utility library). Mirrors the .fs surface almost exactly; most items are marked `internal`. This is the compile-time contract compiler code relies on for lazy values, lock tokens, list/array/string helpers, and name-map collections.

**Namespace(s)** declared: `Internal.Utilities.Library`

**Key declarations** (signatures abbreviated; see illib.md for descriptions):
- `[<Class>] type InterruptibleLazy<'T>` — `new`, `IsValueCreated`, `Value`, `Force`, `static FromValue`.
- `[<AutoOpen>] module internal PervasiveAutoOpens` — `>>>&`, `notlazy`, `|InterruptibleLazy|`, `|RecoverableException|_|`, `isNil`, `isNilOrSingleton`, `isSingleton`, `===`, `LOH_SIZE_THRESHOLD_BYTES : int` (80,000), `reportTime`, `getHole`, `String` extensions (ordinal ops), `Async.RunSynchronouslyImmediate`, `foldOn`, `notFound`.
- `[<AbstractClass>] type DelayInitArrayMap<'T, 'TDictKey, 'TDictValue>` — `GetArray`, `GetDictionary`, `abstract CreateDictionary`.
- `[<AbstractClass>] type internal DelayInitValue<'T>` — `Value`, `abstract Compute` (noted: exceptions are not cached).
- `module internal Order` — `orderBy`, `orderOn`, `toFunction`.
- `module internal Array` — `mapq`, `lengthsEqAndForall2`, `order`, `existsOne`, `existsTrue`, `findFirstIndexWhereTrue`, `revInPlace`, `mapAsync`, `replace`, `areEqual`, `heads`, `isSubArray`, `startsWith`, `endsWith`, `prepend`.
- `module internal Option` — `mapFold`, `attempt`.
- `module internal List` — the full helper set incl. `mapq`/`checkq`, `frontAndBack`, `zip4`/`unzip4`, `*Squared` family, `vMapFold`.
- `module internal ResizeArray` — `chunkBySize`, `mapToSmallArrayChunks`.
- `module internal Span` — `inline exists`.
- `module internal String` — case ops, `isLeadingIdentifierCharacterUpperCase`, `capitalize`/`uncapitalize`, `|StartsWith|_|`, `|Contains|_|`, `getLines`, `extractTrailingIndex`.
- `module internal Dictionary`, `type internal DictionaryExtensions` (`BagAdd`, `BagExistsValueForKey`), `type internal ConcurrentDictionaryExtensions` (`GetOrAddLazy`).
- **Lock/token types** (all `internal`): `ExecutionToken` (interface), `CompilationThreadToken`, `AnyCallerThreadToken`, `LockToken`, `Lock<'LockTokenType>` (`AcquireLock`), and `[<AutoOpen>] module internal LockAutoOpens` (`RequireCompilationThread`, `AssumeCompilationThreadWithoutEvidence`, `AnyCallerThread`, `AssumeLockWithoutEvidence` — note: .fsi shows the .fs's generic `AssumeLockWithoutEvidence<'LockTokenType>` surfaced as returning `#LockToken`).
- `module internal Map` — `tryFindMulti`.
- `[<Struct>] type internal ResultOrException<'T>` + `module internal ResultOrException` (`success`, `raze`, `|?>`, `ForceRaise`, `otherwise`).
- `type internal UniqueStampGenerator<'T>` — `Encode`, `Table`.
- `type internal MemoizationTable<'T, 'U>` — `Apply` (note .fsi doc: "never collected unless whole table is collected").
- `type internal StampedDictionary<'T, 'U>` — `Add`, `UpdateIfExists`, `GetAll`.
- `exception internal UndefinedException`; `type internal LazyWithContextFailure` — `Exception`, `static Undefined`.
- `[<Sealed>] type internal LazyWithContext<'T, 'ctxt>` — `Create`, `NotLazy`, `Force`, `UnsynchronizedForce`, `IsDelayed`, `IsForced` (note: .fs declares `LazyWithContext<'T, 'Ctxt>` as a record type — the .fsi presents it as sealed with `[<NoEquality; NoComparison>]` semantics; also .fsi adds `[<DefaultAugmentation(false)>]` context in .fs — signatures are equivalent for consumers).
- `module internal Tables` — `memoize` (overload constraints differ `#if NET8_0_OR_GREATER`).
- `type internal IPartialEqualityComparer<'T>` + module (`On`, `partialDistinctBy`).
- `type internal NameMap<'T>`, `NameMultiMap<'T>`, `MultiMap<'T,'U>`, `LayeredMap<'Key,'Value>`; modules `NameMap`, `NameMultiMap`, `MultiMap`.
- `[<AutoOpen>] module internal MapAutoOpens` — `Map.Empty`, `Map.AddMany`, `Map.AddOrModify` (plus `Values` under `#if FSHARPCORE_USE_PACKAGE`).
- `[<Sealed>] type internal LayeredMultiMap<'Key, 'Value>` — `Add`, `AddMany`, `TryFind`, `TryGetValue`, `Item`, `Values`, `static Empty`.

**Relationship to .fs**: 1:1 mirror; the .fsi is the authoritative compile-time surface. Notable documentation differences: .fsi carries more doc comments (e.g. on `LazyWithContextFailure`, `CompilationThreadToken` discipline, `GetOrAddLazy` contention behavior).

**Cross-references**: `illib.md` (sibling) for behavioral details; `Caches.md` / `Activity.md` for the two `FSharp.Compiler.*` dependencies used by implementations.
