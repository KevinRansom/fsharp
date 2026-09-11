You are an engineering agent operating inside a terminal environment.
You have write access to the F# compiler repo.

Goal:
Implement the changes required by this document in the F# compiler. After producing the plan, generate a unified diff and apply it directly to the repo.

Requirements:

In this branch
    src\Compiler\Optimize\InnerLambdasToTopLevelFuncs.fs has changes intended to support the realsig+ feature.
They came from this commit: 5b4ddad2aec9822d7f8556223a96cfb3113d3a50 

it merges in a change you made on a different branch.

These two files provide background and the design for the work.  Thay are now out of date, because there are two new sets of work but they are related to the original design.  So they can be consider context but not demands.

   .opencode\Realsig-Rehoming\InnerLambdasToTopLevelFuncs-deepdive-1.md
   .opencode\Realsig-Rehoming\InnerLambdasToTopLevelFuncs-deepdive-2.md

The function: BodyReferencesTypeScopedPrivate uses TryDeclaringEntity ... this one location in the file is a valid use.

All other uses of it were based on the invalid assumption that try declaring entity was set for innerlambdas, in fact TryDeclaringEntity is set to ParentNone.

However --- we wrote some code to get the information
    let innerLambdaDeclaringTyconsM    let innerLambdaDeclaringTyconsM = InnerLambdaDeclaringTyconsOf expr

This is a map of val for the InnerLambdas to a tycon representing the class that originally hosted the code where the lambda was discovered.  
The types of innerlambdadeclaringtycons and the TryDeclaringEntity are different.  But I would like you to figure out what you need for the 
use of TryDeclaringENtity in this file, and convert InnerLambdaDeclaringTyconsOf to fulfilling that requirement.  
And convert the use of TryDeclaringEntities to use the data from InnerLambdaDeclaringTyconsOf expr to split the typars 
for the closure functions

Plan:
Before writing any code, produce a numbered plan describing:
1. What files will be changed
2. What functions will be added or modified
3. Any new types, modules, or helpers
4. How the change integrates with existing compiler passes

Execution:
After I approve the plan:
- Generate a unified diff
- Apply the diff directly to the repo
- Return only the applied diff with no prose

Output Format:
- First: the plan
- Apply the diff directly to the repo
- List the changed files
- Generate a prompt

Discoveries Log:
During execution, append to a file named .opencode/Realsig-Rehoming/discoveries.md 
create it if it doesn't exist.
This change must contain a brief list of key discoveries, insights, or invariants
that impacted the plan or implementation. Focus only on the non-obvious reasoning
steps uncovered while analyzing the relevant compiler passes.

The discoveries update should be concise:
- 1 to 10 bullet points
- Each bullet: one - three sentences
- No prose outside the list

Include this file in the unified diff and apply it along with the code changes.