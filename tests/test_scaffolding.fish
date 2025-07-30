# Test scaffolding utilities for creating temporary monorepo structures
function create_temp_test_dir
    set -l base_name "$argv[1]"
    set -l temp_dir (mktemp -d "/tmp/monorepo_test_$base_name.XXXXXX")
    echo "$temp_dir"
end

function cleanup_temp_test_dir
    set -l temp_dir "$argv[1]"
    if test -d "$temp_dir" && string match -q "/tmp/monorepo_test_*" "$temp_dir"
        rm -rf "$temp_dir"
    end
end

function create_pnpm_workspace
    set -l temp_dir "$argv[1]"
    set -l workspace_name "$argv[2]"
    
    # Create root package.json
    echo '{
  "name": "'"$workspace_name"'",
  "private": true,
  "workspaces": [
    "packages/*"
  ]
}' > "$temp_dir/package.json"

    # Create pnpm-workspace.yaml
    echo 'packages:
  - "packages/*"' > "$temp_dir/pnpm-workspace.yaml"
    
    # Create packages
    mkdir -p "$temp_dir/packages/package-a"
    echo '{
  "name": "@workspace/package-a",
  "version": "1.0.0",
  "main": "index.js"
}' > "$temp_dir/packages/package-a/package.json"

    mkdir -p "$temp_dir/packages/package-b"
    echo '{
  "name": "@workspace/package-b", 
  "version": "1.0.0",
  "main": "index.js"
}' > "$temp_dir/packages/package-b/package.json"

    # Initialize git repo
    cd "$temp_dir"
    git init -q
    git add -A
    git commit -q -m "Initial commit"
end

function create_yarn_workspace
    set -l temp_dir "$argv[1]"
    set -l workspace_name "$argv[2]"
    
    # Create root package.json for Yarn workspaces
    echo '{
  "name": "'"$workspace_name"'",
  "private": true,
  "workspaces": [
    "apps/*",
    "libs/*"
  ]
}' > "$temp_dir/package.json"
    
    # Create apps
    mkdir -p "$temp_dir/apps/web-app"
    echo '{
  "name": "web-app",
  "version": "1.0.0",
  "main": "index.js"
}' > "$temp_dir/apps/web-app/package.json"

    mkdir -p "$temp_dir/apps/mobile-app"
    echo '{
  "name": "mobile-app",
  "version": "1.0.0", 
  "main": "index.js"
}' > "$temp_dir/apps/mobile-app/package.json"

    # Create libs
    mkdir -p "$temp_dir/libs/shared-ui"
    echo '{
  "name": "@company/shared-ui",
  "version": "1.0.0",
  "main": "index.js"
}' > "$temp_dir/libs/shared-ui/package.json"

    # Initialize git repo
    cd "$temp_dir"
    git init -q
    git add -A
    git commit -q -m "Initial commit"
end

function create_cargo_workspace
    set -l temp_dir "$argv[1]"
    set -l workspace_name "$argv[2]"
    
    # Create root Cargo.toml
    echo '[workspace]
members = [
    "crates/lib-core",
    "crates/lib-utils",
    "apps/cli-tool"
]

[workspace.package]
version = "0.1.0"
edition = "2021"' > "$temp_dir/Cargo.toml"

    # Create crates
    mkdir -p "$temp_dir/crates/lib-core/src"
    echo '[package]
name = "lib-core"
version.workspace = true
edition.workspace = true

[dependencies]' > "$temp_dir/crates/lib-core/Cargo.toml"
    echo 'pub fn hello() { println!("Hello from lib-core"); }' > "$temp_dir/crates/lib-core/src/lib.rs"

    mkdir -p "$temp_dir/crates/lib-utils/src"
    echo '[package]
name = "lib-utils"
version.workspace = true
edition.workspace = true

[dependencies]' > "$temp_dir/crates/lib-utils/Cargo.toml"
    echo 'pub fn utils() { println!("Utils function"); }' > "$temp_dir/crates/lib-utils/src/lib.rs"

    # Create apps
    mkdir -p "$temp_dir/apps/cli-tool/src"
    echo '[package]
name = "cli-tool"
version.workspace = true
edition.workspace = true

[dependencies]
lib-core = { path = "../../crates/lib-core" }' > "$temp_dir/apps/cli-tool/Cargo.toml"
    echo 'fn main() { println!("CLI Tool"); }' > "$temp_dir/apps/cli-tool/src/main.rs"

    # Initialize git repo
    cd "$temp_dir"
    git init -q
    git add -A
    git commit -q -m "Initial commit"
end

function create_mixed_workspace
    set -l temp_dir "$argv[1]"
    set -l workspace_name "$argv[2]"
    
    # Create both Node.js and Rust workspace
    echo '{
  "name": "'"$workspace_name"'",
  "private": true,
  "workspaces": [
    "packages/*"
  ]
}' > "$temp_dir/package.json"

    echo '[workspace]
members = [
    "rust-crates/*"
]

[workspace.package]
version = "0.1.0"
edition = "2021"' > "$temp_dir/Cargo.toml"

    # Node packages
    mkdir -p "$temp_dir/packages/frontend"
    echo '{
  "name": "@mixed/frontend",
  "version": "1.0.0"
}' > "$temp_dir/packages/frontend/package.json"

    # Rust crates
    mkdir -p "$temp_dir/rust-crates/backend/src"
    echo '[package]
name = "backend"
version.workspace = true
edition.workspace = true' > "$temp_dir/rust-crates/backend/Cargo.toml"
    echo 'fn main() { println!("Backend"); }' > "$temp_dir/rust-crates/backend/src/main.rs"

    # Initialize git repo
    cd "$temp_dir"
    git init -q
    git add -A
    git commit -q -m "Initial commit"
end