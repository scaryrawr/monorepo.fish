function _monorepo_preview_package_path
    set -f packages (_monorepo_get_workspace_packages)
    set -l package_name $argv
    set -l package_path (echo $packages | jq -r ".[] | select(.name == \"$package_name\") | .path")
    _fzf_preview_file $package_path
end
