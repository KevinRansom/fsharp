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
3. **Before generating a description for any file, check whether the corresponding Markdown file already exists under `.opencode/description/src/<mirrored-path>/<filename>.md`.  
   - If the file exists and contains non-empty content, skip generating a new description.  
   - If the file exists but is empty or clearly incomplete, update it with a new description.  
   - If the file does not exist, generate the description as normal.**
4. **When creating folders under `.opencode/description/src/`, do not delete or recreate any existing folders.  
   Use existing folders as-is and only add new folders when necessary.**
5. **Do not delete, remove, or overwrite any existing files or folders under `.opencode/description/src/`.  
   Only update files when required and only add new files when they do not already exist.**
6. For each file that requires documentation, generate or update the Markdown description file under:
       .opencode/description/src/<mirrored-path>/<filename>.md
7. Ensure the directory structure under `.opencode/description/src/` exactly mirrors the structure under `src/`, adding only the missing parts.
8. Execute the plan file-by-file until all required descriptions are generated.

## Output format
Begin by outputting the full plan:
- list every folder under `src/`
- list every file under each folder
- specify the target output path for each Markdown file
- indicate whether each file will be skipped, updated, or newly generated

After the plan is complete, begin executing it.

## Constraints
- Do not modify any compiler source files.
- Do not generate code.
- Only generate Markdown descriptions.
- Maintain the exact folder hierarchy.
- **Do not delete or recreate any existing files or folders under `.opencode/description/src/`.  
  Preserve all existing content and structure.**

## Execution behavior
- Begin executing the plan immediately after producing it.
- Do not ask for confirmation during execution.
- Continue working automatically until at least 100 files have been successfully generated or updated.
- Track progress internally and continue without pausing unless an error prevents further execution.
- Under no circumstances delete, reset, or recreate any existing files or folders under `.opencode/description/src/`.
- Use all existing files and folders as-is, updating only when necessary and adding new files or folders only when they do not already exist.
