# Searches for pnpm workspace packages and outputs name/path information.
function _monorepo_search_pnpm_workspace
    if test -f "./pnpm-workspace.yaml"
        pnpm list --recursive --depth -1 --json 2>/dev/null | jq -r '[.[] | {name: .name, path: (.path + "/package.json")}]' 2>/dev/null
    else
        echo "[]"
    end
end
