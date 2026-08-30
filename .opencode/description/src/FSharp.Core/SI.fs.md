# SI.fs

## Overview

This file defines the **International System of Units (SI)** as F# units of measure. It contains only `[<Measure>]` type definitions with XML doc comments — no executable logic. It spans two namespaces: `Microsoft.FSharp.Data.UnitSystems.SI.UnitNames` (the full unit names) and `Microsoft.FSharp.Data.UnitSystems.SI.UnitSymbols` (common single-letter abbreviations as synonyms).

## Namespace `Microsoft.FSharp.Data.UnitSystems.SI.UnitNames`

The seven base SI units plus derived units, expressed in terms of base units:

- **Base units**: `metre` (with US-English synonym `meter = metre`), `kilogram` (mass), `second` (time), `ampere` (electric current), `kelvin` (temperature), `mole` (amount of substance), `candela` (luminous intensity).
- **Derived units** (defined via the base/base-derived units):
  - `hertz = / second` (frequency)
  - `newton = kilogram metre / second^2` (force)
  - `pascal = newton / metre^2` (pressure)
  - `joule = newton metre` (energy)
  - `watt = joule / second` (power)
  - `coulomb = second ampere` (charge)
  - `volt = watt / ampere` (potential)
  - `farad = coulomb / volt` (capacitance)
  - `ohm = volt / ampere` (resistance)
  - `siemens = ampere / volt` (conductance)
  - `weber = volt second` (magnetic flux)
  - `tesla = weber / metre^2` (magnetic flux density)
  - `henry = weber / ampere` (inductance)
  - `lumen = candela` (luminous flux)
  - `lux = lumen / metre^2` (illuminance)
  - `becquerel = second^-1` (radioactive activity)
  - `gray = joule / kilogram` (absorbed dose)
  - `sievert = joule / kilogram` (dose equivalent)
  - `katal = mole / second` (catalytic activity)

## Namespace `Microsoft.FSharp.Data.UnitSystems.SI.UnitSymbols`

Defines common abbreviations as `[<Measure>]` synonyms for the UnitNames units (`open`s `UnitNames`): `m`, `kg`, `s`, `A`, `K`, `mol`, `cd`, `Hz`, `N`, `Pa`, `J`, `W`, `C`, `V`, `F`, `S`, `ohm` (explicitly qualified), `Wb`, `T`, `lm`, `lx`, `Bq`, `Gy`, `Sv`, `kat`, `H`.
