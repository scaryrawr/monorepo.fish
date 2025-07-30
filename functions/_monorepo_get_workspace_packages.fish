# Retrieves workspace packages from the monorepo, caching results to optimize repeated lookups.
function _monorepo_get_workspace_packages
    # Create tmp cache directory based on current working directory
    set -l safe_dir (string replace -a '/' '_' "$PWD")
    set -l cache_dir "/tmp/monorepo_cache/$safe_dir"

    if test -f "./package.json"
        set -f pwd_hash (_monorepo_hash (git ls-files '*package.json'))
    end

    if test -f "./Cargo.toml"
        set -f cargo_hash (_monorepo_hash (git ls-files '*Cargo.toml'))
        if test -n "$pwd_hash"
            set -f pwd_hash (string join - $pwd_hash $cargo_hash | sha256sum | cut -d' ' -f1)
        else
            set -f pwd_hash $cargo_hash
        end
    end

    set -l cache_file "$cache_dir/$pwd_hash.json"
    set -l temp_cache_file "$cache_file.tmp"

    if test -f "$cache_file" && test (jq 'length' "$cache_file") -ne 0
        # Just use the cache file if it exists
        cat "$cache_file"
        return 0
    end

    # Otherwise, create the temporary cache file
    mkdir -p "$cache_dir"
    echo "[]" >"$temp_cache_file"

    if test -f "./package.json"
        set -l yarn_packages (_monorepo_search_yarn_workspace)
        set -l pnpm_packages (_monorepo_search_pnpm_workspace)
        set -l bun_packages (_monorepo_search_bun_workspace)
        echo $yarn_packages $pnpm_packages $bun_packages | jq -s 'add' >"$temp_cache_file.tmp"
        mv "$temp_cache_file.tmp" "$temp_cache_file"
    end

    if test -f "./Cargo.toml"
        set -l cargo_packages (_monorepo_search_cargo_workspace)
        echo $cargo_packages | jq -s '.[0] + .[1]' "$temp_cache_file" - >"$temp_cache_file.tmp"
        mv "$temp_cache_file.tmp" "$temp_cache_file"
    end

    if test (jq 'length' "$temp_cache_file") -eq 0
        echo "No supported workspace configuration found."
        rm "$temp_cache_file"
        return 1
    end

    # Move the temporary cache file to the final cache file
    mv "$temp_cache_file" "$cache_file"

    # Validate the final result before returning
    set -l final_result (cat "$cache_file")
    if not _monorepo_validate_packages "$final_result"
        echo "Invalid workspace package data detected."
        rm "$cache_file"
        return 1
    end

    cat "$cache_file"
end
