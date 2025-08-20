# Searches for pnpm workspace packages and outputs name/path information.
function _monorepo_search_pnpm_workspace
    if test -f "./pnpm-workspace.yaml"; and command -q pnpm
        set -l raw_output (pnpm list --recursive --depth -1 --json 2>/dev/null)
        
        # Filter out root package and convert paths to relative
        echo "$raw_output" | jq -r --arg pwd (realpath "$PWD") '
            [.[] | 
             select(.path != $pwd) | 
             {
                name: .name, 
                path: (if (.path | startswith($pwd + "/")) then 
                        "./" + (.path | sub($pwd + "/"; "")) + "/package.json"
                       else 
                        .path + "/package.json" 
                       end)
             }]' 2>/dev/null
    else
        echo "[]"
    end
end
