function _monorepo_get_workspace_packages
    # Create tmp cache directory based on current working directory
    set -l safe_dir (string replace -a '/' '_' $PWD)
    set -l cache_dir /tmp/monorepo_cache/$safe_dir

    if test -f "./package.json"
        set -f pwd_hash (_monorepo_hash (git ls-files '*package.json'))
    end

    if test -f "./Cargo.toml"
        set -f cargo_hash (_monorepo_hash (git ls-files '*Cargo.toml'))
        if test -n "$pwd_hash"
            set -f pwd_hash (string join - $pwd_hash $cargo_hash | sha256sum | awk '{print $1}')
        else
            set -f pwd_hash $cargo_hash
        end
    end

    set -l cache_file "$cache_dir/$pwd_hash.json"

    if test -f $cache_file
        # Just use the cache file if it exists
        cat $cache_file
        return 0
    end

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

    mkdir -p "$cache_dir"
    cat $packages_file | tee "$cache_file"
    rm $packages_file
end
