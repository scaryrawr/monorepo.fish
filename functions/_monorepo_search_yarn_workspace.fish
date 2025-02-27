# Retrieves Yarn workspace package information.
function _monorepo_search_yarn_workspace
    yarn --json workspaces info | jq -r '.data' | jq -r '
        to_entries | map({name: .key, path: ("./" + .value.location + "/package.json")})
    '
end
