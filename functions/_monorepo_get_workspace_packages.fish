# Retrieves workspace packages from the monorepo, caching results to optimize repeated lookups.
function _monorepo_get_workspace_packages
    set -l node_packages '[]'
    if test -f "./package.json"
        set node_packages (_monorepo_search_node_workspace)
    end

    set -l cargo_packages '[]'
    if test -f "./Cargo.toml"
        set -l cargo_packages (_monorepo_search_cargo_workspace)
    end

    echo "$node_packages" "$cargo_packages" | jq -s '.[0] + .[1]'
end
