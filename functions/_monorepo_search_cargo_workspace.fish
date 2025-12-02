# Searches for Cargo workspace packages and outputs name/path information.
function _monorepo_search_cargo_workspace
    fd -a Cargo.toml -x sh -c '
        name=$(grep -m1 "^name" "$1" | sed -E "s/name *= *\"([^\"]+)\"/\1/")
        [ -n "$name" ] && echo "{\"name\":\"$name\",\"path\":\"$1\"}"
    ' _ {} | jq -s .
end
