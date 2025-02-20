function _monorepo_search_workspace
    set -f packages (_monorepo_get_workspace_packages)
    if test $status -ne 0
        return $status
    end

    set -l temp_file (mktemp)
    echo $packages >$temp_file

    set -f fzf_arguments --multi --ansi --preview="_monorepo_preview_package_path {} $temp_file"
    set -f token (commandline --current-token)

    if test -n "$token"
        set --prepend fzf_arguments --query "$token"
    end

    set --prepend fzf_arguments --prompt="Workspace >"

    set -f packages_selected (echo $packages | jq -r '.[].name' | awk '!seen[$0]++' | _fzf_wrapper $fzf_arguments)
    if test $status -eq 0
        commandline --current-token --replace -- (string escape -- $packages_selected | string join ' ')
    end

    commandline --function repaint

    rm $temp_file
end
