#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
packages=(zsh git i3 terminator mise assets nvim espanso)
temp_home=$(mktemp -d)
trap 'rm -rf "$temp_home"' EXIT

printf 'Checking shell syntax...\n'
zsh -n "$repo_root/zsh/.zshrc"
zsh -n "$repo_root/zsh/.zprofile"
zsh -n "$repo_root/zsh/.p10k.zsh"
bash -n "$repo_root/scripts/bootstrap.sh"
bash -n "$repo_root/scripts/check.sh"
bash -n "$repo_root/scripts/clear_trust_agents.sh"
bash -n "$repo_root/scripts/update_magpie.sh"
if [[ -f "$HOME/clear_trust_agents.sh" ]]; then
  bash -n "$HOME/clear_trust_agents.sh"
fi

printf 'Running clear_trust_agents behavior tests...\n'
bash "$repo_root/tests/test_clear_trust_agents.sh"

printf 'Running update_magpie behavior tests...\n'
bash "$repo_root/tests/test_update_magpie.sh"

printf 'Checking Git configuration syntax...\n'
git config --file "$repo_root/git/.gitconfig" --list >/dev/null

printf 'Checking i3 configuration...\n'
i3 -C -c "$repo_root/i3/.config/i3/config"

printf 'Testing a clean Stow installation...\n'
stow --dir="$repo_root" --target="$temp_home" --no-folding "${packages[@]}"
test -L "$temp_home/.zshrc"
test -L "$temp_home/.config/i3/config"
test -L "$temp_home/.config/terminator/config"
test -L "$temp_home/.config/mise/config.toml"
test -L "$temp_home/.local/share/dotfiles/wallpapers/bg-arc.png"
test -L "$temp_home/.config/nvim/init.lua"
test -L "$temp_home/.config/nvim/.luarc.json"
test -L "$temp_home/.config/nvim/.luacheckrc"
test -L "$temp_home/.config/nvim/nvim-pack-lock.json"
test -L "$temp_home/.config/nvim/ftplugin/java.lua"

printf 'Checking for home-directory paths and credential assignments...\n'
hardcoded_home_path="/home/$USER"
if rg -n -F --hidden --glob '!.git/**' --glob '!*.png' "$hardcoded_home_path" "$repo_root"; then
  printf 'Tracked files contain a hard-coded home-directory path.\n' >&2
  exit 1
fi
if rg -n -i --hidden --glob '!.git/**' --glob '!*.png' '(api[_-]?key|access[_-]?token|client[_-]?secret|password|passwd)[[:space:]]*=' "$repo_root"; then
  printf 'Tracked files may contain a credential assignment.\n' >&2
  exit 1
fi

if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$repo_root" diff --check
  git -C "$repo_root" diff --cached --check
fi

printf 'All checks passed.\n'
