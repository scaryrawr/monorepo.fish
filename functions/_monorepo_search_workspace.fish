# Provides an interactive interface to search for workspace packages via fzf.
function _monorepo_search_workspace
    set -f fzf_arguments --delimiter='\t' \
        --with-nth=1 \
        --multi \
        --ansi \
        --preview='_monorepo_preview_package_path (string split \t {} -f1) (string split \t {} -f2)'

    set -f token (commandline --current-token)

    if test -n "$token"
        set --prepend fzf_arguments --query "$token"
    end

    set --prepend fzf_arguments --prompt="Workspace> "

    set -f packages_selected (_monorepo_get_workspace_packages "$packages" | _fzf_wrapper $fzf_arguments | string split \t -f1)
    if test $status -eq 0
        commandline --current-token --replace -- (string escape -- $packages_selected | string join ' ')
    end

    commandline --function repaint
end
