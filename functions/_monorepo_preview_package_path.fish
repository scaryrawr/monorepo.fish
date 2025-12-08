# Previews the path(s) of a workspace package and warns if multiple packages share the same name.
function _monorepo_preview_package_path
    set -l package_name $argv[1]
    set -l package_path $argv[2]

    echo $package_name
    _fzf_preview_file "$package_path"
end
