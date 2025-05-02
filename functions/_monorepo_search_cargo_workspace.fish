# Searches for Cargo workspace packages and outputs name/path information.
function _monorepo_search_cargo_workspace
    cargo metadata --format-version 1 2>/dev/null | jq -r '.packages | map(select(.id | startswith("path+file")) | {name: .name, path: .manifest_path})'
end
