You are a compiler analysis agent. Your task is to extract ONLY the early-stage
pipeline for inner lambdas and inner closures in the F# compiler, covering steps 1–5
of the analysis plan. You must NOT go beyond typechecking.

Your scope is STRICTLY LIMITED to:

1. File discovery
2. Function discovery
3. Data structure extraction
4. Lambda discovery (parsing)
5. Lambda processing (typechecking)

You must NOT describe:
- optimization
- InnerLambdasToTopLevelFuncs
- MakeTopLevelRepresentationDecisions
- ILX or IL generation
- anything after typechecking

Your output must be structured into EXACTLY FIVE SECTIONS:

====================================================================
SECTION 1 — FILES
====================================================================
List all files in the F# compiler source tree that contain code related to:
- ExprLambda
- closure environments
- captured variables
- lambda processing in parsing or typechecking

Only list file paths. No descriptions.

====================================================================
SECTION 2 — FUNCTIONS
====================================================================
For each file listed in Section 1:
- list all functions whose names or signatures indicate they process:
  - lambdas
  - closures
  - captured variables
  - Val creation for lambdas
  - rewriting of ExprLambda
- include approximate line numbers
- DO NOT describe the functions yet

====================================================================
SECTION 3 — DATA STRUCTURES
====================================================================
Extract the definitions (type declarations only) for:
- ExprLambda
- ExprLet
- ExprLetRec
- Val
- ValReprInfo
- closure environment structures (whatever names appear in the code)

Only show:
- type names
- field names
- field types

No explanations.

====================================================================
SECTION 4 — LAMBDA DISCOVERY (PARSING)
====================================================================
For each function in the parser that creates ExprLambda nodes:
- show the code excerpt
- list the fields populated
- list the fields left empty
- DO NOT describe anything beyond parsing

====================================================================
SECTION 5 — TYPECHECKING (TcExpr, TcLambda, TcLetRec)
====================================================================
For each function in typechecking that processes lambdas:
- show the code excerpt
- describe how captured variables are detected
- describe how closure environments are built
- describe how Vals are created for lambdas
- describe what metadata is attached at this stage
- describe what metadata is NOT yet attached

You must STOP after typechecking. Do NOT describe any later passes.

====================================================================

RULES:
- No summaries. Only structured factual output.
- No invented APIs. If unsure, ask for clarification.
- No discussion of optimization or representation decisions.
- No discussion of ILX or IL emission.
- Keep each section strictly within its scope.

Write the results into a file named: .opencode\ConstraintIssue\Investigation-00.md

