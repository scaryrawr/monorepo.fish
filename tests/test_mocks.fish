# Test mocks for external dependencies
# Source this file in test files that need mocked functions

# Mock _fzf_preview_file for testing
function _fzf_preview_file --description "Mock preview function for testing"
    set -l file_path "$argv[1]"
    echo "Preview of: $file_path"
    echo "File contents would be displayed here"
end

# Mock other external functions as needed
function mock_pnpm_output --description "Mock PNPM workspace output"
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