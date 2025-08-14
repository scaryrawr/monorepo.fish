# Testing monorepo.fish

This directory contains comprehensive tests for the monorepo.fish plugin.

## Running Tests

### Run All Tests

```bash
fish tests/run_tests.fish
```

### Run Specific Test Suite

```bash
fish tests/run_tests.fish validation
fish tests/run_tests.fish real_implementation
fish tests/run_tests.fish workspace_detection  
fish tests/run_tests.fish core_functions
```

## Test Structure

### Test Files

- **test_validation.fish** - JSON structure and data format validation
- **test_real_implementation.fish** - Tests actual functions with real external commands when available
- **test_workspace_detection.fish** - Workspace detection with mocked commands for consistency
- **test_core_functions.fish** - Core utility functions and edge cases

### Supporting Files

- **test_framework.fish** - Simple test assertion framework
- **test_scaffolding.fish** - Utilities for creating temporary test workspaces
- **run_tests.fish** - Test runner script

## What Gets Tested

### JSON Output Validation ✓

- Validates that workspace detection produces correctly structured JSON
- Ensures all packages have required `name` and `path` fields
- Tests data types and array structures
- Verifies output can be processed by downstream tools (jq, fzf)

### Real Implementation Tests ✓

- **Uses actual external commands** - Tests with real `yarn`, `pnpm`, `cargo` when available
- **Graceful fallbacks** - Handles missing tools appropriately with fallback logic
- **Separated logic** - Tests the actual workspace detection functions, not mocked versions
- **JSON validation** - Ensures real output matches expected structure

### Workspace Detection ✓

- **PNPM workspaces** - Tests pnpm-workspace.yaml parsing and package discovery
- **Yarn workspaces** - Tests both Yarn 1.x and 2+ workspace formats
- **Cargo workspaces** - Tests Rust workspace member detection
- **Mixed workspaces** - Tests repositories with both Node.js and Rust packages

### Core Functions ✓

- **Caching system** - Validates cache creation and retrieval
- **Hash generation** - Tests consistent hashing for cache keys
- **File path resolution** - Ensures packages can be located correctly
- **Preview functionality** - Tests package preview without fzf interaction
- **Error handling** - Tests graceful failures and edge cases

### What's NOT Tested

The tests deliberately avoid:

- **Interactive fzf functionality** - These require user input and can't be automated
- **Commandline integration** - Tests focus on data processing, not Fish shell integration

## Requirements

Tests require these commands to be available:
- `fish` (Fish shell)  
- `jq` (JSON processor)
- `git` (for repository operations)

External workspace tools are **optional**:
- `yarn`, `pnpm`, `cargo` - Real implementation tests use these when available
- Missing tools are handled gracefully with appropriate fallbacks
- Mocked implementation tests provide mock versions for consistency

## Test Design

The test suite now uses a **dual approach**:

1. **Real Implementation Tests** (`test_real_implementation.fish`)
   - Uses actual external commands when available
   - Tests the real functions, not mocked versions
   - Provides realistic validation of the plugin behavior
   - Gracefully handles missing tools

2. **Controlled Environment Tests** (`test_workspace_detection.fish`)
   - Uses mocked commands for consistent, reproducible results
   - Tests edge cases and specific scenarios
   - Validates expected behavior independent of system tools

### Temporary Workspaces

Tests create realistic monorepo structures in temporary directories:

```fish
set -l temp_dir (create_temp_test_dir "pnpm")
create_pnpm_workspace "$temp_dir" "test-workspace"
cd "$temp_dir"
# ... run tests
cleanup_temp_test_dir "$temp_dir"
```

### Mocking External Commands (in `test_workspace_detection.fish`)

Some tests mock external commands for consistent results:

```fish
function yarn
    if test "$argv[1]" = "--version"
        echo "3.0.0"
    else if test "$argv[1]" = "workspaces"
        echo '{"location":"apps/web","name":"web"}'
    end
end
```

### Using Real Commands (in `test_real_implementation.fish`)

Other tests use actual external commands when available:

```fish
if command -q yarn
    echo "  → Testing with real yarn command"
    set -l yarn_result (_monorepo_search_yarn_workspace)
    # ... test with real yarn output
else
    echo "  → Skipping yarn test (yarn not available)"
end
```

### Assertions

Simple assertion functions validate results:

```fish
assert_equals "expected" "actual" "test description"
assert_json_array_length "$json" "2" "should find 2 packages"
assert_file_exists "/path/to/file" "file should exist"
```

## Adding New Tests

1. **For real implementation tests** - Add to `test_real_implementation.fish`:
   - Use actual external commands when available
   - Handle missing tools gracefully
   - Test realistic scenarios

2. **For controlled tests** - Add to `test_workspace_detection.fish`:
   - Mock external commands for consistent behavior
   - Test specific edge cases and scenarios
   - Ensure reproducible results

3. **General guidelines**:
   - Use test scaffolding to create temporary workspaces
   - Clean up temporary resources
   - Add descriptive assertion messages

Example:

```fish
test_suite "New Feature Tests"

set -l temp_dir (create_temp_test_dir "feature")
# ... setup test workspace
# ... run functions under test
assert_equals "expected" "$result" "feature should work correctly"
cleanup_temp_test_dir "$temp_dir"
```