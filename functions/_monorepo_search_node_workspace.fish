# Searches for Node workspace packages and outputs name/path information.
function _monorepo_search_node_workspace
    if test -f "./package.json"
        rg --files --glob 'package.json' | xargs jq -r '.name + "\t" + input_filename'
    end
end
