function _monorepo_search_cargo_workspace
    cargo metadata --format-version 1 | jq -r '.packages | map(select(.id | startswith("path+file")) | {name: .name, path: .manifest_path})'
end
