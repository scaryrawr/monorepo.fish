# Extracts unique package names from workspace packages JSON for display/selection
function _monorepo_extract_package_names
    set -l packages_json "$argv[1]"
    echo "$packages_json" | jq -r '.[].name' | awk '!seen[$0]++'
end