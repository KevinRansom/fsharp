# ilprint.fs

## Pipeline role

Part of the AbstractIL layer. A DEBUG-only pretty printer for the Abstract IL AST (`ILModule`, `ILTypeDef`, `ILMethodDef`, `ILFieldDef`, etc.) that renders IL in an ILAsm-like textual form to a `TextWriter`. It carries a `ppenv` environment tracking the current class/method generic counts so type variables print as `!n` / `!!n` (Generic EE preferred form), and provides per-node printers, numeric/string/quoted output helpers, security/permission rendering, and a module-level `output_module` entry point.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.ILAsciiWriter` (module `internal`, entirely under `#if DEBUG ... #endif`)
- Uses: `System.IO`, `System.Reflection`, `FSharp.Compiler.IO` (`Bytes`), `Internal.Utilities.Library`, `FSharp.Compiler.AbstractIL.ILX.Types` (`ILX` types/`Apps_*`), `FSharp.Compiler.AbstractIL.IL`.

## Environment

- `tyvar_generator` — mutable counter; `fun n -> n + string i` for fresh generic-parameter names.
- `ppenv` (record) — `{ ilGlobals: ILGlobals; ppenvClassFormals: int; ppenvMethodFormals: int }`.
- `ppenv_enter_method mgparams env`, `ppenv_enter_tdef gparams env`, `ppenv_enter_modul env`, `mk_ppenv ilg`.

## Output primitives

- `output_string`, `output_char`, `output_int`, `output_hex_digit`, `output_qstring` (double-quoted, C-escapes control chars as octal), `output_sqstring` (single-quoted, escapes `'` and `\`), `output_seq sep f os` (joined sequence with separator), `output_parens`, `output_angled`, `output_id`, `output_byte`, `output_bytes` (hex dump), `bits_of_float32` (`BitConverter.ToInt32`), `bits_of_float` (`DoubleToInt64Bits`).
- Scalar printers: `output_u8`/`output_i8`/`output_u16`/`output_i16`/`output_u32`/`output_i32`/`output_u64`/`output_i64`, `output_ieee32`, `output_ieee64`.
- Helpers: `output_at` (field data "at (...)" comment), `output_option`.
- `output_custom_attr_data`, `goutput_custom_attr` (".custom" + method + bytes), `goutput_custom_attrs`.

## Type printing

- `goutput_scoref` — scope refs: Local -> ""; Assembly -> `[name]`; Module -> `[.module name]`; PrimaryAssembly -> `[...primaryAssemblyName]`.
- `goutput_type_name_ref` — scope + `enc/n` path (joined with "/").
- `goutput_tref`, `goutput_typ`, `goutput_typ_with_shortened_class_syntax` (boxed type with no instantiation prints bare `tref`), `goutput_gactuals` (generic instantiation `<...>`), `goutput_gactual`, `goutput_tspec` ("class" + tref + instantiation), `output_arr_bounds` (array shape: single-dimensional -> ""; else per-axis bounds with `...`), `output_tyvar`.
- `goutput_typ` special-cases the well-known primitive types by name against `PrimaryAssemblyILGlobals` (`int8`, `int16`, `int32`, `int64`, `native int`, `unsigned int8/16/32/64`, `native unsigned int`, `float64`, `float32`, `bool`, `char`), then `value class`/`class`, `void`, arrays `[bounds]`, function pointers `method T *(args)`, byref `&`, ptr `*`, `TypeVar` (with the `ppenv` class/method formal logic), `Modified -> NaT` fallback.

## Members, call convs, security

- `goutput_permission`/`goutput_security_decls` — `ILSecurityAction` names and permission-set bytes.
- `goutput_gparam` — generic-parameter name + constraints in parens; `goutput_gparams` `<...>` wrapper.
- `output_bcc` (`fastcall`/`stdcall`/`thiscall`/`cdecl`/`vararg`), `output_callconv` (instance/explicit/static prefix + basic conv).
- `goutput_dlocref` — declaring-type ref printer that elides the global-functions type (`<Module>`, per `isTypeNameForGlobalFunctions`) when `Local`.
- `goutput_mref` — calling conv + return type + `.ctor`/`.cctor` special-cased names + args.
- `goutput_mspec` — like mref plus nested-type access, `[<...>]`-generic-actuals and method-level env.
- `output_member_access` / `output_type_access` (public/private/family/...; `nested` prefix).
- `output_encoding` (ansi/autochar/unicode), `output_field_init` (literal field initializers for every `ILFieldInit` case), `output_init_semantics`.

## Definitions

- `goutput_fdef` — `.field [offset] access [static] [literal] [specialname rtspecialname] [initonly] [notserialized] type name`, then data/literal and custom attrs.
- `goutput_apps` — ILX closure applications (`Apps_tyapp ty ...`, `Apps_app ty ...`, `Apps_done typ` with `-->`).
- `goutput_local` — local + `pinned`; `goutput_param`; `goutput_params`.
- `goutput_ilmbody` — `.zeroinit`, `.maxstack n`, `.locals(...)`.
- `goutput_mbody` — CIL/runtime/native + internalcall/managed/forwardref flags, then `{ security, custom attrs, body, .entrypoint }`.
- `goutput_mdef` — the full `.method` printer: callconv, `hidebysig`, `reqsecobj`, `specialname`, `unmanagedexp`, access, instance/static/virtual/final/newslot/abstract/strict flags, PInvoke impl (`pinvokeimpl("module" as "name" ...)` with calling conv/encoding/nomangle/lasterr), constructor/class-initializer flags, return type, name, generic params, params, `synchronized`/`preservesig`/`noinlining`/`aggressiveinlining`, then the body.
- `goutput_pdef` — `property` getter/setter via `goutput_mref`.
- `goutput_superclass` (`extends`), `goutput_implements` (`implements`).
- `output_type_layout_info` — `.size` / `.pack` for Sequential/Explicit layouts; `splitTypeLayout` returns (`auto`/`sequential`/`explicit`, layout printer).
- `goutput_fdefs`, `goutput_mdefs`, `goutput_pdefs`, `goutput_tdefs` — list printers.
- `goutput_tdef` — the recursive type-def printer: special `.class  interface` prefix, `beforefieldinit`, access, encoding, layout, `sealed`/`abstract`/`serializable`/`import`, name, gparams, `extends`, `implements`, `{` custom attrs / security / layout / fields / methods / nested `goutput_tdefs` `}`. Global-functions types (per `isTypeNameForGlobalFunctions`) inline their members when `contents` is true.
- `goutput_lambdas` — ILX lambda printer (`Lambdas_forall <gf> ...`, `Lambdas_lambda (ps) ...`, `Lambdas_return typ`).

## Module-level

- `output_ver` (`.ver a : b : c : d`), `output_locale` (`.Locale "..."`), `output_publickey` (`.publickey = (...)`).
- `goutput_resource` — `.mresource access name { custom attrs; location }` (Local marked "loc nyi", File/Assembly refs printed).
- `goutput_manifest` — `.assembly [longevity] name { .hash algorithm n; custom attrs; publickey/ver/locale }`.
- `output_module_fragment_aux` — prints type skeleton (`contents=false`) then full definitions (`contents=true`).
- `goutput_module_manifest` — `.module name`, custom attrs, `.imagebase`, `.file alignment`, `.subsystem`, `.corflags`, resources, optional manifest.
- `output_module os ilg modul` — the top-level entry point: manifest + fragments.

## Significant internal logic

- Method/class type variables are printed with `!`/`!!` prefixes based on `ppenvClassFormals`/`ppenvMethodFormals` so generic types render in the runtime's preferred EE form.
- All custom-attribute data is emitted as raw bytes in parens, and marshal attributes are noted as unprinted comments — the output is a structural dump rather than a round-trippable assembler.