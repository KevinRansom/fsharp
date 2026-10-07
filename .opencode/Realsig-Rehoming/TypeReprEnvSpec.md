You are modifying an F# compiler data structure.

Below is the current definition of TypeReprEnv. Your task is to extend it with
a new internal map:

    constraintTypars : Map<Stamp, Typar>

This map contains all typars referenced by constraints on any typar added to
the environment. It must be keyed by Stamp so lookup semantics match reprs.

---------------------------------------------------------------------------
REQUIRED CHANGES
---------------------------------------------------------------------------

1. Add a new constructor parameter:

    constraintTypars : Map<Stamp, Typar>

Store it in the object alongside reprs, count, and templateReplacement.

2. Modify AddOne:

When a typar is added via AddOne:

- If the typar has constraints, traverse those constraints.
- Collect all referenced typars.
- Insert each into constraintTypars using tp.Stamp as the key.
- You may add helper functions such as:

      let rec collectConstraintTypars (tp: Typar) : Typar list = ...

Assume constraints are accessible via tp.Constraints.

AddOne must still add the typar itself to reprs exactly as before.

3. Modify ContainsKey:

ContainsKey must check both reprs and constraintTypars:

    member _.ContainsKey(tp) =
        reprs.ContainsKey(tp.Stamp) ||
        constraintTypars