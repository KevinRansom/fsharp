# FSComp.txt.ko.xlf

Pipeline role: XLIFF satellite localization resource for the FSComp compiler diagnostics string table (src/Compiler/FSComp.txt, base of FSComp.resx and the generated FSComp.SR message module) carrying the bulk of F# compiler warnings and errors; compiled into a satellite resource loaded by the resource manager for the Korean culture.

- File format: XLIFF 1.2 XML (xliff-core-1.2-transitional) with one <file> element, source-language "en", target-language "ko", original "../FSComp.resx".
- Localizes: the main F# compiler diagnostics table in src/Compiler/FSComp.txt (key,message lines; error numbers assigned in Compiler/Driver/CompilerDiagnostics.fs).
- Locale: ko = Korean.
- Trans-units: ~1825.
- Conventions: indexed placeholders {0}..{3}; multi-line templates embed literal \n backslash-n markers; XML-escaped angle brackets (&lt; &gt;); each unit carries an empty <note />.