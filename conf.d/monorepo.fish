if not status is-interactive
    exit
end

monorepo_configure_bindings

function _monorepo_uninstall --on-event monorepo_uninstall
    _monorepo_uninstall_bindings

    functions --erase _monorepo_uninstall _monorepo_migration_message _monorepo_uninstall_bindings monorepo_configure_bindings
end
