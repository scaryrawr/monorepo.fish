# Searches for Bun workspace packages and outputs name/path information.
function _monorepo_search_bun_workspace
    if test -f "./package.json"
        # Try object format first (bun workspaces), then array format
        set -l workspaces (jq -r '.workspaces.packages[]?' package.json 2>/dev/null)
        if test -z "$workspaces"
            set workspaces (jq -r '.workspaces[]?' package.json 2>/dev/null)
        end
        if test -n "$workspaces"
            set -l packages_data
            for pattern in $workspaces
                for pkg in (find . -path "./$pattern/package.json" -not -path "*/node_modules/*" -not -path "*/dist/*" -print 2>/dev/null)
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
            echo "[]"
        end
    else
        echo "[]"
    end
end
