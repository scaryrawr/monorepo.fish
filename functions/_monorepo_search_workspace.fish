function _monorepo_search_workspace
    # Setup cache directory and file based on current directory and its last modified time
    set -l safe_dir (string replace -a '/' '_' $PWD)
    set -l cache_dir /tmp/monorepo_cache/$safe_dir
    mkdir -p $cache_dir
    if test (uname) = Linux
        set -f mod_time (stat --format=%Y .)
    else
        set -f mod_time (stat -f %m .)
    end
    set -l cache_file "$cache_dir/$mod_time.json"

    if test -f $cache_file
        set -f packages (cat $cache_file)
    else
        set -f packages (_monorepo_get_workspace_packages)
        if test $status -ne 0
            return $status
        end
        echo $packages >$cache_file
    end

    set -f fzf_arguments --multi --ansi --preview="_monorepo_preview_package_path {} $cache_file"
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
end
