# Searches for Node workspace packages and outputs name/path information.
function _monorepo_search_node_workspace
    if test -f "./package.json"
        rg --no-heading -N --glob 'package.json' '"name"' | sed -E 's|(.*):.*"name": *"([^"]+)".*|{"name":"\2","path":"\1"}|' | jq -s .
    end
end
