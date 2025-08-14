# Simple test framework for Fish shell functions
set -g TEST_COUNT 0
set -g TEST_PASSED 0
set -g TEST_FAILED 0
set -g TEST_CURRENT_SUITE ""

function test_suite
    set -g TEST_CURRENT_SUITE "$argv[1]"
    echo "Running test suite: $TEST_CURRENT_SUITE"
end

function assert_equals
    set -g TEST_COUNT (math $TEST_COUNT + 1)
    set -l expected "$argv[1]"
    set -l actual "$argv[2]"
    set -l test_name "$argv[3]"
    
    if test "$expected" = "$actual"
        set -g TEST_PASSED (math $TEST_PASSED + 1)
        echo "  ✓ $test_name"
    else
        set -g TEST_FAILED (math $TEST_FAILED + 1)
        echo "  ✗ $test_name"
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
    end
end

function assert_json_contains
    set -g TEST_COUNT (math $TEST_COUNT + 1)
    set -l json_data "$argv[1]"
    set -l expected_key "$argv[2]"
    set -l expected_value "$argv[3]"
    set -l test_name "$argv[4]"
    
    set -l actual_value (echo "$json_data" | jq -r ".$expected_key // empty")
    
    if test "$expected_value" = "$actual_value"
        set -g TEST_PASSED (math $TEST_PASSED + 1)
        echo "  ✓ $test_name"
    else
        set -g TEST_FAILED (math $TEST_FAILED + 1)
        echo "  ✗ $test_name"
        echo "    Expected .$expected_key: $expected_value"
        echo "    Actual .$expected_key:   $actual_value"
        echo "    JSON: $json_data"
    end
end

function assert_json_array_length
    set -g TEST_COUNT (math $TEST_COUNT + 1)
    set -l json_data "$argv[1]"
    set -l expected_length "$argv[2]"
    set -l test_name "$argv[3]"
    
    set -l actual_length (echo "$json_data" | jq 'length')
    
    if test "$expected_length" = "$actual_length"
        set -g TEST_PASSED (math $TEST_PASSED + 1)
        echo "  ✓ $test_name"
    else
        set -g TEST_FAILED (math $TEST_FAILED + 1)
        echo "  ✗ $test_name"
        echo "    Expected length: $expected_length"
        echo "    Actual length:   $actual_length"
        echo "    JSON: $json_data"
    end
end

function assert_file_exists
    set -g TEST_COUNT (math $TEST_COUNT + 1)
    set -l file_path "$argv[1]"
    set -l test_name "$argv[2]"
    
    if test -f "$file_path"
        set -g TEST_PASSED (math $TEST_PASSED + 1)
        echo "  ✓ $test_name"
    else
        set -g TEST_FAILED (math $TEST_FAILED + 1)
        echo "  ✗ $test_name"
        echo "    File does not exist: $file_path"
    end
end

function assert_status_success
    set -g TEST_COUNT (math $TEST_COUNT + 1)
    set -l exit_status "$argv[1]"
    set -l test_name "$argv[2]"
    
    if test "$exit_status" -eq 0
        set -g TEST_PASSED (math $TEST_PASSED + 1)
        echo "  ✓ $test_name"
    else
        set -g TEST_FAILED (math $TEST_FAILED + 1)
        echo "  ✗ $test_name"
        echo "    Expected status: 0"
        echo "    Actual status:   $exit_status"
    end
end

function test_summary
    echo ""
    echo "Test Results:"
    echo "  Total:  $TEST_COUNT"
    echo "  Passed: $TEST_PASSED"
    echo "  Failed: $TEST_FAILED"
    
    if test $TEST_FAILED -eq 0
        echo "  Status: ALL TESTS PASSED ✓"
        return 0
    else
        echo "  Status: SOME TESTS FAILED ✗"
        return 1
    end
end