function _monorepo_get_workspace_packages
    set -l packages_file (mktemp)

    echo "[]" >$packages_file

    if test -f "./package.json"
        set -l yarn_packages (_monorepo_search_yarn_workspace)
        echo $yarn_packages | jq -s '.[0] + .[1]' $packages_file - >$packages_file.tmp
        mv $packages_file.tmp $packages_file
    end

    if test -f "./Cargo.toml"
        set -l cargo_packages (_monorepo_search_cargo_workspace)
        echo $cargo_packages | jq -s '.[0] + .[1]' $packages_file - >$packages_file.tmp
        mv $packages_file.tmp $packages_file
    end

    if test (jq 'length' $packages_file) -eq 0
        echo "No supported workspace configuration found."
        rm $packages_file
        return 1
    end

    cat $packages_file
    rm $packages_file
end
