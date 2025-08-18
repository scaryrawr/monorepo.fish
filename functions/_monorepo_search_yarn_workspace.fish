# Retrieves Yarn workspace package information.
function _monorepo_search_yarn_workspace
    # check for yarn.lock file before assuming yarn workspace
    if test -f "./yarn.lock"
        set -l yarn_version (yarn --version 2>/dev/null)
        if test $status -ne 0
            echo "[]"
            return
        end
        # Check if we're using Yarn 1.x
        if string match -q "1.*" $yarn_version
            yarn --json workspaces info 2>/dev/null | jq -r '.data' | jq -r '
          to_entries | map({name: .key, path: (.value.location + "/package.json")})
      '
        else
            yarn workspaces list --json 2>/dev/null | jq -s '[.[] | select(.location != ".") | {name: .name, path: (.location + "/package.json")}]'
        end
    else
        echo "[]"
    end
end
