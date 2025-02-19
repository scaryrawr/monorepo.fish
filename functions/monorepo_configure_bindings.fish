function monorepo_configure_bindings --description "Installs the default key bindings for monorepo.fish"
    status is-interactive; or return

    set -f key_sequences \e\cw # \c = control, \e = escape
    for mode in default insert
        test -n $key_sequences[1] && bind --mode $mode $key_sequences[1] _monorepo_search_workspace
    end

    function _monorepo_uninstall_bindings --inherit-variable key_sequences
        bind --erase -- $key_sequences
        bind --erase --mode insert -- $key_sequences
    end
end
