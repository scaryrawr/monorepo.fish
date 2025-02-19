function _monorepo_get_workspace_packages
    if test -f "./package.json"
        _monorepo_search_yarn_workspace
    else
        echo "No supported workspace configuration found."
        return 1
    end
end
