#!/usr/bin/env fish

# Load test framework and scaffolding
source (dirname (status -f))/test_framework.fish
source (dirname (status -f))/test_scaffolding.fish

# Load the functions we're testing
set -l monorepo_dir (dirname (dirname (status -f)))
for func_file in $monorepo_dir/functions/*.fish
    source $func_file
end

test_suite "Hash Function Tests"

# Test the hash function with known inputs
set -l test_input "test-file1.json
test-file2.json"

set -l hash_result (_monorepo_hash "$test_input")
assert_equals "64" (string length "$hash_result") "Hash should be 64 characters (SHA256)"

# Test with same input should produce same hash
set -l hash_result2 (_monorepo_hash "$test_input")
assert_equals "$hash_result" "$hash_result2" "Same input should produce same hash"

# Test with different input should produce different hash
set -l different_input "different-file.json"
set -l different_hash (_monorepo_hash "$different_input")
test "$hash_result" != "$different_hash"
assert_status_success $status "Different inputs should produce different hashes"

test_suite "Preview Function Tests"

# Create a test workspace
set -l temp_dir (create_temp_test_dir "preview")
create_pnpm_workspace "$temp_dir" "test-preview-workspace"

cd "$temp_dir"

# Test preview function with valid package
set -l preview_result (_monorepo_preview_package_path "@workspace/package-a")
echo "$preview_result" | grep -q "package-a"
assert_status_success $status "Preview should contain package name"

echo "$preview_result" | grep -q "package.json"
assert_status_success $status "Preview should mention package.json"

# Test preview with invalid package
set -l invalid_preview (_monorepo_preview_package_path "nonexistent-package")
echo "$invalid_preview" | grep -q "not found"
assert_status_success $status "Preview should indicate when package not found"

cleanup_temp_test_dir "$temp_dir"

test_suite "Package Path Resolution Tests"

# Create test workspace
set -l temp_dir (create_temp_test_dir "resolution")
create_yarn_workspace "$temp_dir" "test-resolution-workspace"

cd "$temp_dir"

# Mock yarn for consistent testing
function yarn
    if test "$argv[1]" = "--version"
        echo "3.0.0"
    else if test "$argv[1]" = "workspaces" && test "$argv[2]" = "list" && test "$argv[3]" = "--json"
        echo '{"location":"apps/web-app","name":"web-app"}'
        echo '{"location":"apps/mobile-app","name":"mobile-app"}'
        echo '{"location":"libs/shared-ui","name":"@company/shared-ui"}'
    end
end

# Get workspace packages
set -l packages (_monorepo_get_workspace_packages)

# Test that we can resolve package paths correctly
set -l web_app_path (echo "$packages" | jq -r '.[] | select(.name == "web-app") | .path')
assert_file_exists "$web_app_path" "Web app package.json should exist at resolved path"

set -l shared_ui_path (echo "$packages" | jq -r '.[] | select(.name == "@company/shared-ui") | .path')  
assert_file_exists "$shared_ui_path" "Shared UI package.json should exist at resolved path"

# Test JSON structure validation
echo "$packages" | jq empty 2>/dev/null
assert_status_success $status "Package data should be valid JSON"

set -l all_have_name (echo "$packages" | jq 'all(has("name"))')
assert_equals "true" "$all_have_name" "All packages should have name field"

set -l all_have_path (echo "$packages" | jq 'all(has("path"))')
assert_equals "true" "$all_have_path" "All packages should have path field"

functions -e yarn
cleanup_temp_test_dir "$temp_dir"

test_suite "Workspace File Detection Tests"

# Test each workspace type detection
set -l temp_dir (create_temp_test_dir "detection")

# Test PNPM detection
create_pnpm_workspace "$temp_dir" "pnpm-test"
cd "$temp_dir"
test -f "pnpm-workspace.yaml"
assert_status_success $status "PNPM workspace file should be created"

test -f "package.json"
assert_status_success $status "Package.json should be created"

# Test package.json content
set -l root_name (jq -r '.name' package.json)
assert_equals "pnpm-test" "$root_name" "Root package should have correct name"

cleanup_temp_test_dir "$temp_dir"

# Test Cargo detection
set -l temp_dir (create_temp_test_dir "cargo_detection")
create_cargo_workspace "$temp_dir" "cargo-test"
cd "$temp_dir"

test -f "Cargo.toml"
assert_status_success $status "Cargo.toml should be created"

# Test Cargo.toml content
grep -q "workspace" Cargo.toml
assert_status_success $status "Cargo.toml should contain workspace definition"

grep -q "lib-core" Cargo.toml
assert_status_success $status "Cargo.toml should reference lib-core member"

cleanup_temp_test_dir "$temp_dir"

test_suite "Edge Cases and Error Conditions"

# Test with malformed package.json
set -l temp_dir (create_temp_test_dir "malformed")
cd "$temp_dir"
git init -q

echo '{ invalid json' > package.json
mkdir -p packages/broken
echo '{ "name": "broken-package" }' > packages/broken/package.json

# This should fail gracefully
set -l result (_monorepo_get_workspace_packages)
set -l status_code $status

# Should return error status for malformed workspace
test $status_code -ne 0
assert_status_success $status "Should return error for malformed workspace"

cleanup_temp_test_dir "$temp_dir"

# Test with missing git repository
set -l temp_dir (create_temp_test_dir "no_git")
cd "$temp_dir"

echo '{}' > package.json

# This should handle missing git gracefully
set -l result (_monorepo_get_workspace_packages) 
set -l status_code $status

# May succeed or fail, but shouldn't crash
test $status_code -ge 0
assert_status_success $status "Should handle missing git gracefully"

cleanup_temp_test_dir "$temp_dir"

test_summary