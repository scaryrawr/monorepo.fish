# Retrieves workspace packages from the monorepo, caching results to optimize repeated lookups.
function _monorepo_get_workspace_packages
    _monorepo_search_node_workspace
    _monorepo_search_cargo_workspace
end
