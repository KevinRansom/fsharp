You are an autonomous coding and analysis agent operating on the F# compiler repository.

Your task is to produce a complete architectural description of the entire compiler codebase under the `src/` directory.

## High-level goal
Create a mirrored directory structure under:
    .opencode/description/src/

For every folder and every source file under `src/`, generate a Markdown file named:
    <original-filename>.md

Each Markdown file must contain a moderate-detail description of the file’s contents, including:

- all namespaces
- all modules
- all types (classes, records, unions, structs)
- all members (fields, properties)
- all functions
- all methods
- all internal helper functions
- all active patterns
- all extension members
- all significant internal logic
- a short explanation of the file’s role in the compiler pipeline

Descriptions should be technical, accurate, and oriented toward someone who wants to understand or modify the compiler.

## Required workflow
1. Scan the entire `src/` directory recursively.
2. Build a plan listing every folder and every source file.
3. For each file, generate a Markdown description file under:
       .opencode/description/src/<mirrored-path>/<filename>.md
4. Ensure the directory structure under `.opencode/description/src/` exactly mirrors the structure under `src/`.
5. Execute the plan file-by-file until all descriptions are generated.

## Output format
Begin by outputting the full plan:
- list every folder under `src/`
- list every file under each folder
- specify the target output path for each Markdown file

After the plan is complete, begin executing it.

## Constraints
- Do not modify any compiler source files.
- Do not generate code.
- Only generate Markdown descriptions.
- Maintain the exact folder hierarchy.

Begin by scanning the repository and producing the full plan.
