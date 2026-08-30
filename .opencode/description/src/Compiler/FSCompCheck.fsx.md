# FSCompCheck.fsx

## Pipeline role
A standalone F# script run as a repository check that validates the ordering of error
codes in `FSComp.txt`. It is executed from the `Compiler` directory.

## How it works
- Reads `__SOURCE_DIRECTORY__ + "/FSComp.txt"` line by line.
- For each line, trims leading spaces and `#` and finds the longest digit-run at the
  start (`intStringEndIndex`) to extract a leading integer error code, if any.
- Folds over the file with a counter stack:
  - A line starting with an integer either extends the current counter (when the code is
    >= the current head) or starts a new counter.
- At the end:
  - Zero codes found -> `failwith` "contained no error codes but expected at least one".
  - Exactly one final code -> success (all numbered codes form a single ascending group).
  - Otherwise -> throws, listing the codes after which the ascending run "broke".

## Role
CI sanity check: guarantees error numbers are not inserted out of order (each new code
must be larger than the previous within its group), which keeps backward compatibility of
stable diagnostic numbers in the compiler.