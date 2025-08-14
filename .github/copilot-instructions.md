# Copilot Instructions for monorepo.fish

## Project Overview

This is a Fish shell plugin that provides fuzzy-finding capabilities for monorepo workspace packages. It integrates with [fzf.fish](https://github.com/PatrickF1/fzf.fish) to enable quick navigation between packages in Yarn, pnpm, Bun, and Cargo workspaces.

## Architecture & Key Components

### Core Data Flow

1. **Detection**: Functions in `functions/_monorepo_search_*_workspace.fish` detect workspace types and extract package metadata
2. **Aggregation**: `_monorepo_get_workspace_packages.fish` combines all workspace types and implements git-based caching
3. **Interaction**: `_monorepo_search_workspace.fish` provides fzf integration for package selection
4. **Binding**: `monorepo_configure_bindings.fish` sets up Ctrl+Alt+W keybinding

### JSON Output Contract

All workspace detection functions MUST return JSON arrays with objects containing `{name: string, path: string}` where `path` points to the package.json/Cargo.toml file. Use `jq -s '.'` to convert individual objects to arrays and `jq -n --arg name "$name" --arg path "$path" '{name: $name, path: $path}'` for safe JSON construction.

### Caching Strategy

- Cache key: SHA256 hash of `git ls-files '*package.json'` and `git ls-files '*Cargo.toml'`
- Cache location: `/tmp/monorepo_cache/{safe_dir}/{hash}.json`
- Cache invalidation: Automatic when package files change (detected via git)

## Development Workflows

### Testing

```fish
# Run all tests
fish tests/run_tests.fish

# Run specific test suite
fish tests/run_tests.fish validation
fish tests/run_tests.fish workspace_detection
```

### Testing New Workspace Functions

1. Create test scaffolding in a temp directory with `test_scaffolding.fish` patterns
2. Test JSON output format: `your_function | jq 'type'` should return `"array"`
3. Validate schema: Each object must have `.name` and `.path` properties
4. Test error cases: missing config files, malformed JSON, missing dependencies

## Fish Shell Conventions

### Function Structure

- Private functions: `_monorepo_*` prefix
- Public functions: `monorepo_*` prefix
- File location: `functions/{function_name}.fish`
- Use `set -f` for function-local variables, `set -l` for local scope

### Error Handling Pattern

```fish
if test -f "./config.json"
    set -l result (jq -r '.something' config.json 2>/dev/null)
    if test $status -eq 0 -a -n "$result" -a "$result" != "null"
        # Process result
    else
        echo "[]"  # Always return empty array on failure
    end
else
    echo "[]"  # Always return empty array when config missing
end
```

### Common Patterns

- Check external commands: `if type -q command_name`
- Early returns: `test $status -ne 0; and return $status`
- Array building: `set -a array_var $new_item` then `printf '%s\n' $array_var | jq -s '.'`

## Integration Points

### Dependencies

- **fzf.fish**: Required for fuzzy finding (`_fzf_wrapper`, `_fzf_preview_file`)
- **External tools**: jq (required), git (required), workspace tools (pnpm, yarn, cargo - optional)
- **Shell builtin**: Uses Fish's `bind`, `string`, `test`, `set` extensively

### Key Files for Workspace Support

- `_monorepo_search_*_workspace.fish`: Add new workspace type detection here
- `_monorepo_get_workspace_packages.fish`: Update aggregation logic for new workspace types
- Test in both `test_workspace_detection.fish` and `test_real_implementation.fish`

## Common Tasks

### Adding New Workspace Type

1. Create `functions/_monorepo_search_newtype_workspace.fish`
2. Follow JSON output contract (return array of `{name, path}` objects)
3. Add to `_monorepo_get_workspace_packages.fish` aggregation
4. Add tests following `test_workspace_detection.fish` patterns
5. Update cache key generation if using different config files

### Debugging Cache Issues

- Check `/tmp/monorepo_cache/` for cached files
- Verify hash generation: `git ls-files '*package.json' | _monorepo_hash`
- Clear cache: `rm -rf /tmp/monorepo_cache/`
