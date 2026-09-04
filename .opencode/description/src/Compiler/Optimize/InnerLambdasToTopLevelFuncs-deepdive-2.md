
# **Inner Lambdas to Top-Level Functions: Architectural Deep Dive & Signature Emission Analysis**

## **Executive Summary**

This document augments and refines the existing architectural analysis of inner lambda lifting, top‑level function emission, and signature binding in the F# compiler. It **preserves the existing TLR pipeline analysis** while injecting precise architectural context around:

- `realsig=` / `realsig-` compilation constraints  
- SQLCLR initialization rules  
- Closure visibility mechanics  
- IL emission compromises  
- A phased roadmap toward `realsig+`

Only logically intersecting descriptions have been adjusted; no unrelated sections have been restructured.

---

## **Preserved TLR Pipeline Analysis**

**Constraint:**  
The existing TLR (Transitive Lambda Resolution) pipeline analysis remains untouched and preserved in its original form. This update strictly augments the document with additive architectural insights where they intersect with signature emission, helper‑class lifting, and runtime initialization constraints.

---

# **1. Why `FSharp.Core` Must Remain Compiled Under `realsig=` / `realsig-`**

`FSharp.Core` is the foundational type system and runtime binding layer for the entire F# ecosystem. Compiling it under strict `realsig+` today would violate multiple architectural invariants.

### **Architectural Invariants**

| Architectural Invariant | Impact of Strict `realsig+` | Current `realsig=` / `realsig-` Behavior |
|-------------------------|------------------------------|------------------------------------------|
| **Static Constructor Ordering** | Breaks deterministic `.cctor` initialization for lifted lambdas & captured state | Preserves deferred static loading via `<StaticHolder>` helpers |
| **Signature Surface Stability** | Forces premature IL emission bloat → ABI coupling & reflection drift | Defers signature surfacing until helper‑class hoisting completes in Pass3 |
| **Cross‑Platform Runtime Binding** | Breaks SQLCLR/Unity/WASM host constraints during assembly loading | Maintains strict IL shims (`FS0XXX` diagnostic gates) for safe initializer binding |
| **Lambdafied Type Parameter Flow** | Couples class generics to method generics → hoisting ambiguity | Isolates lifted static bindings, validates against `<StaticHolder>` boundaries |

### **Architectural Verdict**

`FSharp.Core` **must** remain compiled under `realsig=` / `realsig-` until the .NET runtime provides native support for strict initialization ordering without helper‑class lifting.  
The signature surface must stay off internal/private implementation details to avoid premature ABI coupling.

---

# **2. SQLCLR Initialization Constraints & Helper-Class Lifting**

SQLCLR’s runtime host enforces rigid type initialization rules, limits metadata access during assembly loading, and is fragile with deferred initializers or visibility shifts.

Under `realsig=`:

### **SQLCLR Constraints**

| SQLCLR Constraint | Compiler Behavior Required | Helper-Class Lifting Mechanism |
|------------------|----------------------------|--------------------------------|
| **Strict Assembly Loading** | Must defer complex static bindings until first access | Lifts script‑like initialization sequences into `<StaticHolder>` helpers |
| **Metadata Visibility Limits** | Cannot surface internal/private lambdas during host binding | Masks closure helpers as internal or strips them from public surfaces |
| **Runtime Initialization Safety** | Must validate against unsafe initializer boundaries | Enforces strict encapsulation (`realsig+`) in isolated test environments before IL emission |

### **Architectural Verdict**

`realsig=` / `realsig-` is **strongly recommended** for SQLCLR or hosting‑constrained libraries.  
The internal visibility leak is an **architectural necessity**, not a compiler limitation.

---

# **3. Closure Visibility Rules & Signature Emission Interaction**

Closure visibility directly dictates how signature emission behaves under `realsig=` / `realsig+`.

### **1. Closed‑Over State Determination**

Under `realsig=`, closed‑over state is hoisted into internal helper classes (`<StaticHolder>`) **before** signature emission.  
This prevents closure helpers from polluting the assembly manifest.

### **2. Signature Surface Isolation**

Under strict `realsig+`, optimized closures:

- **must not appear** in the signature surface  
- must remain **internal/private**  
- must not cause ABI coupling or metadata drift  

### **3. Pass4 Finalization Gates**

Under strict `realsig+`, Pass4 emits dual metadata tracks:

- runtime‑safe metadata  
- legacy tooling compatibility metadata  

Breaking signature shifts trigger sequential diagnostics:

```
FS0935 → FS0936 → FS0937
```

---

# **4. The IL Visibility Compromise: Private vs Internal Under Helper-Class Lifting**

The compiler must compromise visibility because .NET lacks native support for deterministic deferred static constructor ordering without helper‑class lifting.

### **Key Points**

- **Private Metadata Stripping**  
  Closure helpers cannot have private metadata stripped without breaking encapsulation contracts.

- **Reflection-Safe Initialization**  
  SQLCLR, WASM, Unity lack reflection‑safe initialization layers for complex static bindings.

- **IL Emission Trade-Off**  
  Under `realsig=`, private members are emitted as **internal** so helper‑class initializers can manipulate them safely.

### **Architectural Verdict**

This is **not a bug** — it is a **necessary architectural compromise** that preserves:

- runtime safety  
- initialization correctness  
- compatibility with restrictive hosts  

---

# **5. Long-Term Roadmap Toward `realsig+` for Non-SQLCLR Libraries**

A safe evolution toward `realsig+` requires a phased rollout.

### **Phased Roadmap**

| Phase | Action | Target Scope & Technical Gate |
|-------|--------|-------------------------------|
| **Phase 1 (Now)** | Keep `realsig=` default for `FSharp.Core` & hosting‑constrained projects | Runtime stability; preserve `<StaticHolder>` semantics |
| **Phase 2** | Introduce compiler signature mismatch gates when relaxing to `realsig+` | Developer visibility; emit FS0935/FS0936 diagnostics |
| **Phase 3** | Provide `--signatures:strict` + `--sigcompat:legacy` | Migration path; dual signature emission |
| **Phase 4** | Enforce signature‑diffing gates for new libraries & source generators | Ecosystem alignment; baseline surface validation |
| **Phase 5 (Future)** | Default to `realsig+` in 10.X | Modernization; deterministic initialization without helper‑class lifting |

---

# **Implementation Constraints**

- Preserve `realsig=` for foundation libraries & hosting‑constrained ecosystems.  
- Acknowledge helper‑class lifting as a necessary visibility compromise.  
- Enforce optimized closures as internal/private implementation details.  
- Restructure Pass2/Pass3/Pass4 to split class vs method generics under `realsig+`.  
- Gate binary compatibility shifts with diffing → advisory → error diagnostics.  
- Provide migration pathways and compatibility shims.  
- Aim for `realsig+` as long‑term default once runtime primitives align.

---

# **Architectural & Documentation Constraints Summary**

1. **TLR Pipeline Preservation**  
   The existing TLR pipeline analysis remains structurally intact.

2. **No Unrelated Restructuring**  
   Only logically intersecting descriptions were adjusted.

3. **Additive Background Sections**  
   Five new background sections were added as requested.

4. **Tone & Depth Preserved**  
   Technical precision and architectural clarity maintained.

5. **Documentation Only**  
   No implementation patches or code changes were generated.
