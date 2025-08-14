#!/usr/bin/env fish

# Test runner for monorepo.fish
# Usage: fish tests/run_tests.fish [test_name]

set -l script_dir (dirname (status -f))
set -l test_files "$script_dir/test_validation.fish" "$script_dir/test_real_implementation.fish" "$script_dir/test_workspace_detection.fish" "$script_dir/test_core_functions.fish"

function run_single_test
    set -l test_file "$argv[1]"
    set -l test_name (basename "$test_file" .fish)
    
    echo "========================================"
    echo "Running $test_name"
    echo "========================================"
    
    # Run the test file directly
    fish "$test_file"
    set -l test_result $status
    
    echo ""
    
    return $test_result
end

function main
    set -l target_test "$argv[1]"
    set -l total_failures 0
    set -l script_dir (dirname (status -f))
    set -l test_files "$script_dir/test_validation.fish" "$script_dir/test_real_implementation.fish" "$script_dir/test_workspace_detection.fish" "$script_dir/test_core_functions.fish"
    
    echo "Starting monorepo.fish test suite"
    echo ""
    
    # Check dependencies
    if not command -q jq
        echo "Error: jq is required for tests but not found"
        return 1
    end
    
    if not command -q git
        echo "Error: git is required for tests but not found"
        return 1
    end
    
    # Run specific test if requested
    if test -n "$target_test"
        set -l test_file "$script_dir/test_$target_test.fish"
        if test -f "$test_file"
            run_single_test "$test_file"
            return $status
        else
            echo "Error: Test file not found: $test_file"
            echo "Available tests:"
            for file in $test_files
                echo "  "(basename "$file" .fish | string replace 'test_' '')
            end
            return 1
        end
    end
    
    # Run all tests
    for test_file in $test_files
        if test -f "$test_file"
            run_single_test "$test_file"
            set -l test_status $status
            if test $test_status -ne 0
                set total_failures (math $total_failures + 1)
            end
        else
            echo "Warning: Test file not found: $test_file"
        end
    end
    
    echo "========================================"
    echo "Test Suite Summary"
    echo "========================================"
    
    if test $total_failures -eq 0
        echo "All test suites passed! ✓"
        return 0
    else
        echo "$total_failures test suite(s) failed ✗"
        return 1
    end
end

# Make the script executable when run directly
if test (status -f) = (status filename)
    main $argv
end