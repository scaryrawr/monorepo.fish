function _monorepo_preview_package_path
    set -l packages
    if test -n "$argv[2]"
        set packages (cat $argv[2] | jq -r '.')
    else
        set packages (_monorepo_get_workspace_packages)
    end
    set -l package_name $argv[1]
    set -l package_path (echo $packages | jq -r ".[] | select(.name == \"$package_name\") | .path")
    _fzf_preview_file $package_path
end
