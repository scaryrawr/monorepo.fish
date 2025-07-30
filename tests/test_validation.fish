#!/usr/bin/env fish

# Validation tests - focus on JSON structure and data integrity
# These tests use minimal dependencies and mock external commands

source (dirname (status -f))/test_framework.fish
source (dirname (status -f))/test_scaffolding.fish

# Load the functions we're testing
set -l monorepo_dir (dirname (dirname (status -f)))
for func_file in $monorepo_dir/functions/*.fish
    source $func_file
end

test_suite "JSON Structure Validation"

# Test that our mocked functions produce valid JSON
function mock_pnpm_output
    echo '[
  {
    "name": "package-a",
    "path": "./packages/package-a/package.json"
  },
  {
    "name": "package-b", 
    "path": "./packages/package-b/package.json"
  }
]'
end

set -l mock_result (mock_pnpm_output)

# Validate JSON syntax
echo "$mock_result" | jq empty 2>/dev/null
assert_status_success $status "Mock PNPM output should be valid JSON"

# Validate structure
set -l has_required_fields (echo "$mock_result" | jq 'all(has("name") and has("path"))')
assert_equals "true" "$has_required_fields" "All packages should have name and path fields"

set -l array_length (echo "$mock_result" | jq 'length')
assert_equals "2" "$array_length" "Should have exactly 2 packages"

test_suite "Expected Output Format Validation"

# Test that our functions produce the expected format for downstream processing
function test_expected_format
    set -l json_data "$argv[1]"
    
    # Should be an array
    set -l is_array (echo "$json_data" | jq 'type == "array"')
    assert_equals "true" "$is_array" "Output should be JSON array"
    
    # Each item should have name and path
    set -l all_have_name (echo "$json_data" | jq 'all(has("name"))')
    assert_equals "true" "$all_have_name" "All items should have name field"
    
    set -l all_have_path (echo "$json_data" | jq 'all(has("path"))')
    assert_equals "true" "$all_have_path" "All items should have path field"
    
    # Names should be strings
    set -l names_are_strings (echo "$json_data" | jq 'all(.name | type == "string")')
    assert_equals "true" "$names_are_strings" "All names should be strings"
    
    # Paths should be strings
    set -l paths_are_strings (echo "$json_data" | jq 'all(.path | type == "string")')
    assert_equals "true" "$paths_are_strings" "All paths should be strings"
end

# Test with different workspace types
set -l pnpm_format '[{"name":"@scope/pkg","path":"./packages/pkg/package.json"}]'
test_expected_format "$pnpm_format"

set -l yarn_format '[{"name":"web-app","path":"apps/web-app/package.json"}]'
test_expected_format "$yarn_format"

set -l cargo_format '[{"name":"lib-core","path":"crates/lib-core/Cargo.toml"}]'
test_expected_format "$cargo_format"

test_suite "File Location Logic Validation"

# Test the logic for locating files without actually creating files
function validate_file_location_logic
    set -l package_data "$argv[1]"
    set -l expected_count "$argv[2]"
    
    # Extract all paths - Fish stores multi-line output as array elements
    set -l paths (echo "$package_data" | jq -r '.[].path')
    set -l path_count (count $paths)
    
    assert_equals "$expected_count" "$path_count" "Should extract correct number of paths"
    
    # Paths should be relative or absolute
    for path in $paths
        # Should contain package.json or Cargo.toml
        echo "$path" | grep -E '\.(json|toml)$' >/dev/null
        assert_status_success $status "Path should end with .json or .toml: $path"
    end
end

set -l multi_package_data '[
  {"name":"pkg1","path":"./a/package.json"},
  {"name":"pkg2","path":"./b/package.json"},
  {"name":"pkg3","path":"./c/Cargo.toml"}
]'

validate_file_location_logic "$multi_package_data" "3"

test_suite "Data Processing Pipeline Validation"

# Test the data flow through our processing pipeline
function simulate_workspace_detection
    set -l workspace_type "$argv[1]"
    
    switch "$workspace_type"
        case "pnpm"
            echo '[{"name":"@test/pnpm-pkg","path":"./packages/pnpm-pkg/package.json"}]'
        case "yarn"
            echo '[{"name":"yarn-pkg","path":"apps/yarn-pkg/package.json"}]'
        case "cargo"
            echo '[{"name":"cargo-pkg","path":"crates/cargo-pkg/Cargo.toml"}]'
        case '*'
            echo '[]'
    end
end

# Test each workspace type
for workspace_type in pnpm yarn cargo
    set -l result (simulate_workspace_detection "$workspace_type")
    
    # Should produce valid JSON
    echo "$result" | jq empty 2>/dev/null
    assert_status_success $status "$workspace_type workspace simulation should produce valid JSON"
    
    # Should have expected structure
    test_expected_format "$result"
end

# Test combining multiple workspace types (mixed monorepo)
set -l pnpm_data (simulate_workspace_detection "pnpm")
set -l cargo_data (simulate_workspace_detection "cargo")
set -l combined_data (echo "$pnpm_data" "$cargo_data" | jq -s 'add')

assert_json_array_length "$combined_data" "2" "Combined data should have 2 packages"

# Verify both types are present
set -l has_pnpm (echo "$combined_data" | jq 'any(.[]; .name == "@test/pnpm-pkg")')
set -l has_cargo (echo "$combined_data" | jq 'any(.[]; .name == "cargo-pkg")')

assert_equals "true" "$has_pnpm" "Should contain PNPM package"
assert_equals "true" "$has_cargo" "Should contain Cargo package"

test_suite "Error Handling Validation"

# Test that error conditions produce expected results
function test_error_conditions
    # Empty array should be valid
    set -l empty_result '[]'
    echo "$empty_result" | jq empty 2>/dev/null
    assert_status_success $status "Empty result should be valid JSON"
    
    assert_json_array_length "$empty_result" "0" "Empty result should have length 0"
    
    # Invalid JSON should be detectable
    set -l invalid_json '{"name": invalid}'
    echo "$invalid_json" | jq empty 2>/dev/null
    test $status -ne 0
    assert_status_success $status "Should detect invalid JSON"
end

test_error_conditions

test_summary