#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/scripts/update_magpie.sh"
case_dir=$(mktemp -d)
trap 'rm -rf -- "$case_dir"' EXIT

fake_bin="$case_dir/fake-bin"
test_home="$case_dir/home"
asset="$case_dir/magpie-linux-amd64"
mkdir -p "$fake_bin" "$test_home/.config/magpie"
cp /usr/bin/true "$asset"

cat >"$test_home/.config/magpie/settings.json" <<'EOF'
{"proxyCustom":"http://proxy.test:7892"}
EOF

cat >"$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$@" >>"$MAGPIE_TEST_CURL_LOG"
output=''
write_out=0
while (($#)); do
  case "$1" in
    --output) output="$2"; shift 2 ;;
    --write-out) write_out=1; shift 2 ;;
    *) shift ;;
  esac
done

if ((write_out)); then
  printf 'https://github.com/yetone/magpie-releases/releases/tag/v0.1.1853'
else
  cp -- "$MAGPIE_TEST_ASSET" "$output"
fi
EOF
chmod 0755 "$fake_bin/curl"

MAGPIE_TEST_ASSET="$asset" \
MAGPIE_TEST_CURL_LOG="$case_dir/curl.log" \
HOME="$test_home" PATH="$fake_bin:$PATH" \
  bash "$script" >"$case_dir/output"

cmp -- "$asset" "$test_home/.local/bin/magpie"
grep -Fx -- '--proxy' "$case_dir/curl.log" >/dev/null
grep -Fx -- 'http://proxy.test:7892' "$case_dir/curl.log" >/dev/null
grep -Fx -- 'https://github.com/yetone/magpie-releases/releases/download/v0.1.1853/magpie-linux-amd64' \
  "$case_dir/curl.log" >/dev/null
grep -F 'Installed Magpie v0.1.1853' "$case_dir/output" >/dev/null

printf 'update_magpie tests passed.\n'
