# monorepo.fish

These are some tools for working in monorepos in fish shell.

Currently some keybindings for fuzzy finding to "extend" [fzf.fish](https://github.com/PatrickF1/fzf.fish).

## Workspace Detection

monorepo.fish supports automatic detection and listing of workspace packages for:
- Yarn workspaces (via package.json)
- pnpm workspaces (via pnpm-workspace.yaml)
- Bun workspaces (via workspaces field in package.json)
- Cargo workspaces (via Cargo.toml)

It will use the appropriate tool or parse the config files to list all workspace packages in your monorepo.

## Installing

We leverage functions that come with [fzf.fish](https://github.com/PatrickF1/fzf.fish) (so please install it).

```fish
fisher install PatrickF1/fzf.fish scaryrawr/monorepo.fish
```

## Keybindings

| Keybinding | Description             |
| ---------- | ----------------------- |
| ctrl+alt+w | List Workspace packages |

## Testing

The plugin includes comprehensive tests to validate workspace detection and JSON output:

```bash
# Run all tests
fish tests/run_tests.fish

# Run specific test suite
fish tests/run_tests.fish validation
```

See [tests/README.md](tests/README.md) for detailed testing information.
