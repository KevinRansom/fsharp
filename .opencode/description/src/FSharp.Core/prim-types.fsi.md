# src/Checker/FSharp.Core/prim-types.fsi 

## File Role 
F# primitive types signature interface file (.fsi) defining all core F# primitive type signatures exposed as public APIs in the FSharp.Core library. Defines the foundational scalar types: int, int32, int64, float, float32, double, byte, sbyte, bool, string, unit, char.

## Types and Modules
### Primitive Value Types:
- `int` / `int32`: 32-bit signed integer type with operators (+, -, *, /, %)
- `int64`: 64-bit signed integer  
- `float` / `double`: 64-bit floating point
- `float32`: 32-bit floating point
- `byte`, `sbyte`, `nativeint`, `unativeint`

### Other Primitive Types:
- `bool`: Boolean type (true/false) with operators (&&, ||)  
- `string`: Unicode string type with operations (length, subscripting, concatenation)
- `unit`: Singleton unit type () with literal value ()
- `char`: Character type representing a single Unicode character

## Compiler Pipeline Role
These primitive types form the foundational scalar types in F# language. They are defined in FSharp.Core and referenced by all other checked typing information during semantic analysis of expression checking.
