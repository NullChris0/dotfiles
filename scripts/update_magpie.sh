#!/usr/bin/env bash
set -euo pipefail

repository='yetone/magpie-releases'
install_dir="$HOME/.local/bin"
target="$install_dir/magpie"
settings_file="${XDG_CONFIG_HOME:-$HOME/.config}/magpie/settings.json"

die() {
  printf 'update_magpie: %s\n' "$*" >&2
  exit 1
}

proxy="${MAGPIE_UPDATE_PROXY:-}"
if [[ -z "$proxy" && -r "$settings_file" ]] && command -v jq >/dev/null 2>&1; then
  proxy=$(jq -r '.proxyCustom // .proxy // empty' "$settings_file") ||
    die "could not read $settings_file"
fi

if [[ -n "$proxy" && ! "$proxy" =~ ^https?://[^[:space:]]+$ ]]; then
  die 'proxy must be an http(s) URL'
fi

case "$(uname -m)" in
  x86_64) asset='magpie-linux-amd64' ;;
  aarch64|arm64) asset='magpie-linux-arm64' ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

curl_args=(
  --fail --silent --show-error --location --proto '=https' --tlsv1.2
  --connect-timeout 15 --max-time 1800 --speed-time 60 --speed-limit 1024
  --retry 3 --retry-all-errors
)
if [[ -n "$proxy" ]]; then
  curl_args+=(--proxy "$proxy")
fi

latest_url=$(curl "${curl_args[@]}" --output /dev/null --write-out '%{url_effective}' \
  "https://github.com/$repository/releases/latest")
prefix="https://github.com/$repository/releases/tag/"
[[ "$latest_url" == "$prefix"* ]] || die "unexpected release URL: $latest_url"
tag="${latest_url#"$prefix"}"
[[ "$tag" =~ ^v[0-9]+(\.[0-9]+){2}([-.][0-9A-Za-z.]+)?$ ]] ||
  die "unexpected release tag: $tag"

if [[ -e "$target" || -L "$target" ]]; then
  [[ -f "$target" && ! -L "$target" && -O "$target" ]] ||
    die "$target must be a regular file owned by $(id -un)"
  installed_version=$("$target" --version 2>/dev/null || true)
  [[ "$installed_version" == "magpie ${tag#v}" ]] && {
    printf 'Magpie %s is already installed.\n' "$tag"
    exit 0
  }
fi

[[ ! -L "$install_dir" ]] || die "$install_dir must not be a symlink"
mkdir -p -- "$install_dir"
[[ -d "$install_dir" && -O "$install_dir" ]] ||
  die "$install_dir must be a directory owned by $(id -un)"

umask 077
temp_file=$(mktemp "$install_dir/.magpie-download.XXXXXX")
trap 'rm -f -- "$temp_file"' EXIT

printf 'Downloading Magpie %s...\n' "$tag"
curl "${curl_args[@]}" --output "$temp_file" \
  "https://github.com/$repository/releases/download/$tag/$asset"

[[ "$(head -c 4 -- "$temp_file")" == $'\x7fELF' ]] || die 'download is not an ELF executable'
[[ "$(stat -c '%s' -- "$temp_file")" -ge 4096 ]] || die 'download is unexpectedly small'

chmod 0755 -- "$temp_file"
mv -f -- "$temp_file" "$target"
trap - EXIT
printf 'Installed Magpie %s at %s. Restart Magpie to use it.\n' "$tag" "$target"
