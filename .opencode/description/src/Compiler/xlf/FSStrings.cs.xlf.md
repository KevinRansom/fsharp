# FSStrings.cs.xlf

Pipeline role: XLIFF satellite localization resource for the FSStrings compiler-service string table (src/Compiler/FSStrings.resx, embedded as FSStrings.resources in FSharp.Compiler.Service) holding longer diagnostics typed against RichText classification in Compiler/Facilities/RichText.fsi; compiled into a satellite resource loaded by the resource manager for the Czech culture.

- File format: XLIFF 1.2 XML (xliff-core-1.2-transitional) with one <file> element, source-language "en", target-language "cs", original "../FSStrings.resx".
- Localizes: FSStrings table in src/Compiler/FSStrings.resx (e.g. signature-versus-implementation mismatch messages).
- Locale: cs = Czech.
- Trans-units: ~355 (24 currently status "new").
- Conventions: indexed placeholders {0}..{3}; some multi-line templates embed literal \n markers; each unit carries an empty <note />.