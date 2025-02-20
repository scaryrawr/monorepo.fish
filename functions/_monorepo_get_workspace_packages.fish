function _monorepo_get_workspace_packages
    set -l packages "[]"

    if test -f "./package.json"
        set -l yarn_packages (_monorepo_search_yarn_workspace)
        set packages (jq -n --argjson existing_packages "$packages" --argjson new_packages "$yarn_packages" '$existing_packages + $new_packages')
    end

    if test -f "./Cargo.toml"
        set -l cargo_packages (_monorepo_search_cargo_workspace)
        set packages (jq -n --argjson existing_packages "$packages" --argjson new_packages "$cargo_packages" '$existing_packages + $new_packages')
    end

    if test (echo $packages | jq 'length') -eq 0
        echo "No supported workspace configuration found."
        return 1
    end

    echo $packages
end
