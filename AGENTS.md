# Agent Guidelines for monorepo.fish

## Build/Test/Lint Commands

This Fish shell plugin provides fuzzy-finding for monorepo workspace packages.

- **Tests**: `fish tests/run_tests.fish` (run all tests)
- **Single test**: `fish tests/run_tests.fish [test_name]` (e.g., `validation`, `workspace_detection`)
- No build/lint needed (Fish functions are interpreted)

**Requirements**: `fish`, `jq`, `git`

## Code Style Guidelines

### Function Structure & Naming
- All functions in `functions/` with `.fish` extension
- Private: `_monorepo_*` prefix, Public: `monorepo_*` prefix
- Include `--description` parameter

### Fish Shell Conventions
- Variables: `set -f` (function-local), `set -l` (local scope)
- Conditionals: Use `test` over `[`
- String ops: Use `string` builtin
- Status checks: `test $status -eq 0` or early returns: `test $status -ne 0; and return $status`
- Quoting: Double quotes for variables

### JSON Output Contract
- All workspace functions MUST return JSON arrays: `[{name: string, path: string}]`
- Use `jq -n --arg name "$name" --arg path "$path" '{name: $name, path: $path}'` for safe construction
- Return `echo "[]"` on errors (never empty output)

### Error Handling Pattern
```fish
if test -f "config.json"
    set -l result (jq -r '.field' config.json 2>/dev/null)
    test $status -eq 0 -a -n "$result" -a "$result" != "null"; or echo "[]"; and return
    # Process result
else
    echo "[]"
end
```

### Dependencies & Caching
- Requires: fzf.fish plugin, jq, git (pnpm/yarn/cargo optional)
- Cache: `/tmp/monorepo_cache/{safe_dir}/{hash}.json` (SHA256 of `git ls-files`)
- Cache key: Based on package.json and Cargo.toml file changes
