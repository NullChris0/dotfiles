#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
packages=(zsh git i3 terminator mise assets nvim espanso)
required_commands=(git stow zsh)
optional_commands=(i3 i3status rofi dex xss-lock i3lock nm-applet blueman-applet dunst pactl xrandr feh picom flameshot terminator direnv mise fzf rg)

missing_required=()
for command_name in "${required_commands[@]}"; do
  command -v "$command_name" >/dev/null 2>&1 || missing_required+=("$command_name")
done

if ((${#missing_required[@]})); then
  printf 'Missing required commands: %s\n' "${missing_required[*]}" >&2
  exit 1
fi

printf 'Checking for Stow conflicts...\n'
stow --dir="$repo_root" --target="$HOME" --no-folding --simulate --verbose=1 "${packages[@]}"

printf 'Linking dotfiles into %s...\n' "$HOME"
stow --dir="$repo_root" --target="$HOME" --no-folding "${packages[@]}"

mkdir -p "$HOME/.config/zsh" "$HOME/.config/i3"
if [[ ! -e "$HOME/.config/zsh/local.zsh" ]]; then
  install -m 0600 "$repo_root/zsh/.config/zsh/local.zsh.example" "$HOME/.config/zsh/local.zsh"
fi
if [[ ! -e "$HOME/.config/i3/local.conf" ]]; then
  install -m 0644 "$repo_root/i3/.config/i3/local.conf.example" "$HOME/.config/i3/local.conf"
fi

missing_optional=()
for command_name in "${optional_commands[@]}"; do
  command -v "$command_name" >/dev/null 2>&1 || missing_optional+=("$command_name")
done

if ((${#missing_optional[@]})); then
  printf 'Optional commands not found: %s\n' "${missing_optional[*]}"
fi

printf 'Dotfiles installed. Run scripts/check.sh to validate them.\n'
