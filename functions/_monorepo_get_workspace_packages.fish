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

    mkdir -p "$cache_dir"
    echo "[]" >$cache_file

    if test -f "./package.json"
        set -l yarn_packages (_monorepo_search_yarn_workspace)
        echo $yarn_packages | jq -s '.[0] + .[1]' $cache_file - >$cache_file.tmp
        mv $cache_file.tmp $cache_file
    end

    if test -f "./Cargo.toml"
        set -l cargo_packages (_monorepo_search_cargo_workspace)
        echo $cargo_packages | jq -s '.[0] + .[1]' $cache_file - >$cache_file.tmp
        mv $cache_file.tmp $cache_file
    end

    if test (jq 'length' $cache_file) -eq 0
        echo "No supported workspace configuration found."
        rm $cache_file
        return 1
    end

    cat $cache_file
end
