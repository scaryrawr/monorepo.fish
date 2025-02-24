function _monorepo_preview_package_path
    if test -n "$argv[2]"
        set -f packages (cat "$argv[2]")
    else
        set -f packages (_monorepo_get_workspace_packages)
    end
    set -l package_name $argv[1]
    set -l package_paths (echo $packages | jq -r ".[] | select(.name == \"$package_name\") | .path")
    if test (count $package_paths) -gt 1
        echo (set_color yellow)"Warning: multiple packages with the same name found"(set_color normal)
    end
    for package_path in $package_paths
        echo $package_path
        _fzf_preview_file $package_path
    end
end
