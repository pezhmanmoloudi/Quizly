# RuboCop

Run RuboCop on the current codebase or a specific file, auto-fix safe offenses, and confirm clean output.

## Usage

- `/rubocop` — check the whole project
- `/rubocop <file>` — check a specific file or glob
- `/rubocop --fix` — auto-correct safe offenses project-wide
- `/rubocop --fix <file>` — auto-correct a specific file

## Standard workflow

1. **Run the check** using the GitHub formatter (matches CI):
   ```
   bin/rubocop -f github $ARGS
   ```

2. **If there are offenses**, report each one with:
   - File path and line number
   - Cop name
   - The problematic code
   - What the rule requires and why

3. **Auto-fix safe offenses** (when asked or when `--fix` is passed):
   ```
   bin/rubocop -A -f github $ARGS
   ```
   After fixing, re-run the check to confirm no regressions.

4. **Explain unfixable offenses** — for cops that require manual changes (style decisions, complexity, etc.), show the code and explain what needs to change and why the cop exists.

5. **Confirm clean** — always end with a final run showing zero offenses or list what remains.

## Notes

- Always use `bin/rubocop` (not `rubocop` directly) to pick up the project's bundled version.
- Use `-f github` to match CI output format (`::error file=...`).
- `-A` applies both safe (`-a`) and unsafe auto-corrections. If you want only safe fixes, use `-a` instead.
- RuboCop config lives in `.rubocop.yml` at the project root.
