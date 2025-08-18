function _monorepo_search_pnpm_workspace
    if test -f "./pnpm-workspace.yaml"
        if command -v pnpm >/dev/null 2>&1
            # Try pnpm list first, with error handling for different pnpm versions
            set -l pnpm_output (pnpm list --recursive --depth -1 --json 2>/dev/null)
            if test $status -eq 0 && test -n "$pnpm_output"
                # Handle both array and object formats that pnpm might return
                # First get the array, then process it
                set -l pnpm_array (echo "$pnpm_output" | jq -s '.[0]' 2>/dev/null)
                if test $status -eq 0 && test -n "$pnpm_array"
                    set -l current_dir (realpath .)
                    echo "$pnpm_array" | jq --arg pwd "$current_dir" '[.[] | select(.name != null and .name != "" and .path != $pwd) | {name: .name, path: (if .path | startswith($pwd) then "./" + (.path | ltrimstr($pwd + "/")) + "/package.json" else .path + "/package.json" end)}]' 2>/dev/null
                    if test $status -eq 0
                        return 0
                    end
                end
            end
        end
        
        # Fallback: parse pnpm-workspace.yaml and find all matching package.json files
        if command -v yq >/dev/null 2>&1
            set -l patterns (yq e '.packages[]' pnpm-workspace.yaml 2>/dev/null)
            set -l packages_data
            for pattern in $patterns
                for pkg in (find . -path "./$pattern/package.json" -print 2>/dev/null)
                    set -l name (jq -r .name $pkg 2>/dev/null)
                    if test -n "$name" -a "$name" != "null"
                        set -a packages_data (jq -n --arg name "$name" --arg path "$pkg" '{name: $name, path: $path}')
                    end
                end
            end
            if test -n "$packages_data"
                printf '%s\n' $packages_data | jq -s '.'
            else
                echo "[]"
            end
        else
            echo "pnpm-workspace.yaml found but neither pnpm nor yq is installed." >&2
            echo "[]"
            return 1
        end
    else
        echo "[]"
    end
end
