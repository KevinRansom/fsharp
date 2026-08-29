# FSharpEmbedResXSource.fs

> Pipeline role: MSBuild code generator that turns a `.resx` file into F# source — generating a module (`module` whose name mirrors a `fullModuleName`) with static members per resource string. Companion to `FSharpEmbedResourceText`.
> Namespace: `FSharp.Build` (line 3).

---

## `type FSharpEmbedResXSource() = inherit Task()`

**Properties**: `EmbeddedResource` (the `.resx` item), `IntermediateOutputPath`, `TargetFramework`, `_generatedSource` behind `GeneratedSource` (`[<Output>]`).

**Generation** (`generateSource resx fullModuleName generateLegacy generateLiteral`, line 43):

- Reads the `.resx` XML; extracts the resource strings (and their `comment`), splitting the `namespace`/`module` name from the item.
- Emits `namespace {0}` (line 30 boilerplate) then `module <moduleName> =` with `let (..)`/property members:
  - when `generateLegacy` — `let <name> = "<escaped literal>"` (UTF-16 escaped);
  - when `generateLiteral` — `let <name> = "<escaped value>"`;
  - otherwise `let <name> = "<raw value>"`.
- `Execute()` (line ~163) iterates `EmbeddedResource` items honoring the `GenerateSource` boolean metadata (`getBooleanMetadata "GenerateSource"`), and verifies `GeneratedSource` gets the output file item.

---

## Related

- Sibling: `FSharpEmbedResourceText.fs`; used by FSharp.Core `FSStrings`-style resources in the build.