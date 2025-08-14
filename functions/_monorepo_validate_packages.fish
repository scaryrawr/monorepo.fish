# Validates workspace package data structure and content
function _monorepo_validate_packages
    set -l packages_json "$argv[1]"
    
    # Check if valid JSON
    echo "$packages_json" | jq empty 2>/dev/null
    if test $status -ne 0
        return 1
    end
    
    # Check if it's an array
    set -l is_array (echo "$packages_json" | jq 'type == "array"')
    if test "$is_array" != "true"
        return 1
    end
    
    # Check that all items have required fields
    set -l all_have_name (echo "$packages_json" | jq 'all(has("name"))')
    set -l all_have_path (echo "$packages_json" | jq 'all(has("path"))')
    
    if test "$all_have_name" != "true" -o "$all_have_path" != "true"
        return 1
    end
    
    return 0
end