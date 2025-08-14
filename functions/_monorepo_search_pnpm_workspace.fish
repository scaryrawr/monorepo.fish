# Searches for pnpm workspace packages and outputs name/path information.
function _monorepo_search_pnpm_workspace
    if test -f "./pnpm-workspace.yaml"
        if type -q pnpm
            # Try pnpm list first, with error handling for different pnpm versions
            set -l pnpm_output (pnpm list --recursive --depth -1 --json 2>/dev/null)
            if test $status -eq 0 && test -n "$pnpm_output"
                # Handle both array and object formats that pnpm might return
                echo "$pnpm_output" | jq -s '
                    if type == "array" then 
                        [.[] | {name: .name, path: (.path + "/package.json")}] 
                    else 
                        [. | {name: .name, path: (.path + "/package.json")}] 
                    end' 2>/dev/null
                if test $status -eq 0
                    return 0
                end
            end
        end
        
        # Fallback: parse pnpm-workspace.yaml and find all matching package.json files
        if type -q yq
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
