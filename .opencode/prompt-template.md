You are an engineering agent operating inside a terminal environment.
You have write access to the F# compiler repo.

Goal:
Implement <change> in the F# compiler. After producing the plan, generate a unified diff and apply it directly to the repo.

Context:

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