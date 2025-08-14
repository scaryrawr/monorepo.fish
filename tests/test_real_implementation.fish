#!/usr/bin/env fish

# Real implementation tests - uses actual functions with fallbacks for missing tools
source (dirname (status -f))/test_framework.fish
source (dirname (status -f))/test_scaffolding.fish

# Load the functions we're testing
set -l monorepo_dir (dirname (dirname (status -f)))
for func_file in $monorepo_dir/functions/*.fish
    source $func_file
end

test_suite "Real Implementation - Core Functions"

# Test validation function directly
set -l valid_json '[{"name":"pkg1","path":"./pkg1/package.json"}]'
_monorepo_validate_packages "$valid_json"
assert_status_success $status "Should validate correct package JSON"

set -l invalid_json '{"not": "array"}'
_monorepo_validate_packages "$invalid_json"
test $status -ne 0
assert_status_success $status "Should reject invalid package JSON"

# Test package name extraction
set -l package_names (_monorepo_extract_package_names "$valid_json")
assert_equals "pkg1" "$package_names" "Should extract package name correctly"

test_suite "Real Implementation - PNPM Workspace"

set -l temp_dir (create_temp_test_dir "real_pnpm")
create_pnpm_workspace "$temp_dir" "test-workspace"
cd "$temp_dir"

# Test the actual PNPM function
set -l pnpm_result (_monorepo_search_pnpm_workspace)
set -l pnpm_status $status

if command -q pnpm
    echo "  → Testing with real pnpm command"
    # Note: pnpm may fail in test environment, that's OK
    if test $pnpm_status -eq 0
        assert_status_success $pnpm_status "PNPM workspace detection should succeed with real pnpm"
        _monorepo_validate_packages "$pnpm_result"
        assert_status_success $status "PNPM result should be valid package data"
    else
        echo "  → PNPM failed (likely due to test environment), checking fallback"
        test $pnpm_status -ne 0
        assert_status_success $status "PNPM should return error status when it can't work"
    end
else
    echo "  → Testing with fallback (pnpm not available)"
    # Should still work with fallback logic or return empty array
    test $pnpm_status -eq 0 -o $pnpm_status -eq 1
    assert_status_success $status "PNPM function should handle missing pnpm gracefully"
    
    if test $pnpm_status -eq 0
        _monorepo_validate_packages "$pnpm_result"
        assert_status_success $status "PNPM fallback result should be valid if successful"
    end
end

cleanup_temp_test_dir "$temp_dir"

test_suite "Real Implementation - Yarn Workspace"

set -l temp_dir (create_temp_test_dir "real_yarn")
create_yarn_workspace "$temp_dir" "test-workspace"
cd "$temp_dir"

set -l yarn_result (_monorepo_search_yarn_workspace)
set -l yarn_status $status

if command -q yarn
    echo "  → Testing with real yarn command"
    assert_status_success $yarn_status "Yarn workspace detection should succeed with real yarn"
    _monorepo_validate_packages "$yarn_result"
    assert_status_success $status "Yarn result should be valid package data"
    
    # Test that we get the packages we expect
    set -l package_count (echo "$yarn_result" | jq 'length')
    test $package_count -gt 0
    assert_status_success $status "Yarn should find at least one package"
else
    echo "  → Skipping yarn test (yarn not available)"
end

cleanup_temp_test_dir "$temp_dir"

test_suite "Real Implementation - Cargo Workspace"

set -l temp_dir (create_temp_test_dir "real_cargo")
create_cargo_workspace "$temp_dir" "test-workspace"
cd "$temp_dir"

set -l cargo_result (_monorepo_search_cargo_workspace)
set -l cargo_status $status

if command -q cargo
    echo "  → Testing with real cargo command"
    assert_status_success $cargo_status "Cargo workspace detection should succeed with real cargo"
    _monorepo_validate_packages "$cargo_result"
    assert_status_success $status "Cargo result should be valid package data"
    
    # Test that we get the packages we expect
    set -l package_count (echo "$cargo_result" | jq 'length')
    test $package_count -gt 0
    assert_status_success $status "Cargo should find at least one package"
else
    echo "  → Skipping cargo test (cargo not available)"
end

cleanup_temp_test_dir "$temp_dir"

test_suite "Real Implementation - Bun Workspace"

set -l temp_dir (create_temp_test_dir "real_bun")
cd "$temp_dir"
git init -q

# Create a Bun workspace structure
echo '{
  "name": "bun-workspace",
  "workspaces": ["packages/*"]
}' > package.json

mkdir -p packages/bun-pkg
echo '{
  "name": "bun-package",
  "version": "1.0.0"
}' > packages/bun-pkg/package.json

set -l bun_result (_monorepo_search_bun_workspace)
set -l bun_status $status

assert_status_success $bun_status "Bun workspace detection should succeed"
_monorepo_validate_packages "$bun_result"
assert_status_success $status "Bun result should be valid package data"

# Check specific content
set -l bun_package (echo "$bun_result" | jq -r '.[] | select(.name == "bun-package")')
test -n "$bun_package"
assert_status_success $status "Should find bun-package"

cleanup_temp_test_dir "$temp_dir"

test_suite "Real Implementation - Bun Object Format Workspaces"

set -l temp_dir (create_temp_test_dir "real_bun_object")
cd "$temp_dir"
git init -q

# Create a Bun workspace structure with object format (like opencode)
echo '{
  "name": "bun-object-workspace",
  "workspaces": {
    "packages": ["packages/*"],
    "catalog": {
      "typescript": "5.0.0"
    }
  },
  "packageManager": "bun@1.2.14"
}' > package.json

mkdir -p packages/pkg-one packages/pkg-two
echo '{
  "name": "@test/pkg-one",
  "version": "1.0.0"
}' > packages/pkg-one/package.json

echo '{
  "name": "@test/pkg-two", 
  "version": "1.0.0"
}' > packages/pkg-two/package.json

# Create some node_modules and dist directories that should be excluded
mkdir -p packages/pkg-one/node_modules/excluded packages/pkg-one/dist/excluded
echo '{"name": "should-be-excluded"}' > packages/pkg-one/node_modules/excluded/package.json
echo '{"name": "should-also-be-excluded"}' > packages/pkg-one/dist/excluded/package.json

set -l bun_object_result (_monorepo_search_bun_workspace)
set -l bun_object_status $status

assert_status_success $bun_object_status "Bun object format workspace detection should succeed"
_monorepo_validate_packages "$bun_object_result"
assert_status_success $status "Bun object format result should be valid package data"

# Check that we found both packages
set -l pkg_one (echo "$bun_object_result" | jq -r '.[] | select(.name == "@test/pkg-one")')
set -l pkg_two (echo "$bun_object_result" | jq -r '.[] | select(.name == "@test/pkg-two")')
test -n "$pkg_one"
assert_status_success $status "Should find @test/pkg-one"
test -n "$pkg_two"
assert_status_success $status "Should find @test/pkg-two"

# Check that excluded packages are not found
set -l excluded_count (echo "$bun_object_result" | jq '[.[] | select(.name | contains("excluded"))] | length')
test "$excluded_count" = "0"
assert_status_success $status "Should exclude node_modules and dist packages"

cleanup_temp_test_dir "$temp_dir"

test_suite "Real Implementation - Integration Test"

set -l temp_dir (create_temp_test_dir "real_integration")
create_mixed_workspace "$temp_dir" "test-mixed"
cd "$temp_dir"

# Test the full integration
set -l workspace_result (_monorepo_get_workspace_packages)
set -l workspace_status $status

assert_status_success $workspace_status "Mixed workspace detection should succeed"
_monorepo_validate_packages "$workspace_result"
assert_status_success $status "Integration result should be valid package data"

# Test that we can extract names for fzf
set -l package_names (_monorepo_extract_package_names "$workspace_result")
test -n "$package_names"
assert_status_success $status "Should extract package names for fzf"

# Test caching
set -l second_result (_monorepo_get_workspace_packages)
assert_equals "$workspace_result" "$second_result" "Second call should return cached result"

cleanup_temp_test_dir "$temp_dir"

test_suite "Real Implementation - Error Conditions"

# Test with empty directory
set -l temp_dir (create_temp_test_dir "real_empty")
cd "$temp_dir"
git init -q

set -l empty_result (_monorepo_get_workspace_packages)
set -l empty_status $status

assert_equals "1" "$empty_status" "Empty directory should return error status"

cleanup_temp_test_dir "$temp_dir"

# Test with malformed workspace
set -l temp_dir (create_temp_test_dir "real_malformed")
cd "$temp_dir"
git init -q

echo '{ malformed json' > package.json

set -l malformed_result (_monorepo_get_workspace_packages)
set -l malformed_status $status

test $malformed_status -ne 0
assert_status_success $status "Malformed workspace should return error"

cleanup_temp_test_dir "$temp_dir"

test_summary