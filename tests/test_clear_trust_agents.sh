#!/usr/bin/env bash
set -uo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/scripts/clear_trust_agents.sh"
case_dir=""
last_output=""
last_status=0
tests_run=0
tests_failed=0

cleanup() {
  [[ -z "$case_dir" ]] || rm -rf -- "$case_dir"
}
trap cleanup EXIT

new_case() {
  cleanup
  case_dir=$(mktemp -d)
  export FAKE_STATE="$case_dir"
  : >"$FAKE_STATE/log"
  : >"$FAKE_STATE/system_units"
  : >"$FAKE_STATE/user_units"
  : >"$FAKE_STATE/active_system_units"
  : >"$FAKE_STATE/active_user_units"
  : >"$FAKE_STATE/refuse_units"
  : >"$FAKE_STATE/overridden_units"
  : >"$FAKE_STATE/unstoppable_units"
  printf '0\n' >"$FAKE_STATE/ps_count"
}

ps() {
  local count snapshot
  count=$(<"$FAKE_STATE/ps_count")
  count=$((count + 1))
  printf '%s\n' "$count" >"$FAKE_STATE/ps_count"
  snapshot="$FAKE_STATE/ps.$count"
  if [[ ! -f "$snapshot" ]]; then
    snapshot="$FAKE_STATE/ps.default"
  fi
  [[ ! -f "$snapshot" ]] || command cat -- "$snapshot"
}

systemctl() {
  local scope=system unit="" active_file
  {
    printf 'systemctl'
    printf ' %q' "$@"
    printf '\n'
  } >>"$FAKE_STATE/log"

  if [[ "${1-}" == "--user" ]]; then
    scope=user
    shift
  fi
  active_file="$FAKE_STATE/active_${scope}_units"

  case "${1-}" in
    list-unit-files|list-units)
      command cat -- "$FAKE_STATE/${scope}_units"
      ;;
    show)
      unit="${2-}"
      if [[ " $* " == *" RefuseManualStop "* ]]; then
        if command grep -Fxq -- "$unit" "$FAKE_STATE/refuse_units"; then
          printf 'yes\n'
        else
          printf 'no\n'
        fi
      fi
      ;;
    is-active)
      unit="${!#}"
      command grep -Fxq -- "$unit" "$active_file"
      ;;
    start)
      unit="${2-}"
      if ! command grep -Fxq -- "$unit" "$active_file"; then
        printf '%s\n' "$unit" >>"$active_file"
      fi
      ;;
    stop)
      unit="${2-}"
      if command grep -Fxq -- "$unit" "$FAKE_STATE/unstoppable_units"; then
        return 1
      fi
      if [[ "$scope" == system ]] &&
        command grep -Fxq -- "$unit" "$FAKE_STATE/refuse_units" &&
        ! command grep -Fxq -- "$unit" "$FAKE_STATE/overridden_units"; then
        return 1
      fi
      command grep -Fxv -- "$unit" "$active_file" >"$active_file.next" || true
      command mv -- "$active_file.next" "$active_file"
      ;;
    daemon-reload) ;;
  esac
}

sudo() {
  local path unit
  {
    printf 'sudo'
    printf ' %q' "$@"
    printf '\n'
  } >>"$FAKE_STATE/log"

  case "${1-}" in
    systemctl)
      shift
      systemctl "$@"
      ;;
    tee)
      path="${2-}"
      unit="${path#/run/systemd/system/}"
      unit="${unit%%.d/*}"
      if ! command grep -Fxq -- "$unit" "$FAKE_STATE/overridden_units"; then
        printf '%s\n' "$unit" >>"$FAKE_STATE/overridden_units"
      fi
      while IFS= read -r _; do :; done
      ;;
    mkdir) ;;
    kill) ;;
    *) "$@" ;;
  esac
}

sleep() {
  printf 'sleep %q\n' "${1-}" >>"$FAKE_STATE/log"
}

export -f ps systemctl sudo sleep

run_script() {
  local output_file="$FAKE_STATE/output"
  set +e
  bash "$script" "$@" >"$output_file" 2>&1
  last_status=$?
  set -e
  last_output=$(<"$output_file")
}

fail() {
  printf '    %s\n' "$*" >&2
  return 1
}

assert_status() {
  local expected="$1"
  [[ "$last_status" -eq "$expected" ]] ||
    fail "expected status $expected, got $last_status; output: $last_output"
}

assert_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "missing expected text: $needle"
}

assert_file_contains() {
  local file="$1" needle="$2"
  command grep -Fq -- "$needle" "$file" || fail "missing expected file text: $needle"
}

assert_file_not_contains() {
  local file="$1" needle="$2"
  ! command grep -Fq -- "$needle" "$file" || fail "unexpected file text: $needle"
}

assert_before() {
  local haystack="$1" first="$2" second="$3" prefix suffix
  [[ "$haystack" == *"$first"* ]] || return 1
  prefix="${haystack%%"$first"*}"
  suffix="${haystack#"$prefix$first"}"
  [[ "$suffix" == *"$second"* ]] || fail "expected '$first' before '$second'"
}

assert_file_count() {
  local file="$1" needle="$2" expected="$3" actual
  actual=$(command grep -Fc -- "$needle" "$file" || true)
  [[ "$actual" -eq "$expected" ]] ||
    fail "expected $expected occurrences of '$needle', got $actual"
}

test_status_matches_all_qianxin_paths() {
  new_case
  command cat >"$FAKE_STATE/ps.default" <<'EOF'
  101 root qaxsafed - /opt/qaxsafe/qaxsafed
  102 nc qaxtray_5 /opt/qaxsafe/qaxtray_5 /opt/qaxsafe/qaxtray_5
  103 nc sqaxsafeforcnos /opt/qaxsafe/sqaxsafeforcnos_5 /opt/qaxsafe/sqaxsafeforcnos_5 --minishow
  104 nc qaxsafecheckui_ /opt/qaxsafe/safecheck/qaxsafecheckui_5 /opt/qaxsafe/safecheck/qaxsafecheckui_5 --hide
  105 nc renamed-client /opt/qaxsafe/future/renamed-client /usr/bin/launcher --flag
  106 nc launcher /usr/bin/launcher /opt/qaxsafe/future/first-command --flag
  107 nc unrelated /usr/bin/unrelated /usr/bin/unrelated --mentions /opt/qaxsafe/not-the-command
  108 nc AtRuStAgEnT /opt/atrust/AtRuStAgEnT /opt/atrust/AtRuStAgEnT
  109 nc qaxtray_4 /opt/qaxsafe/qaxtray_4 /opt/qaxsafe/qaxtray_4
EOF

  run_script status --no-services --no-proxy-clean

  assert_status 0 || return
  assert_contains "$last_output" "qaxsafed" || return
  assert_contains "$last_output" "qaxtray_5" || return
  assert_contains "$last_output" "qaxtray_4" || return
  assert_contains "$last_output" "sqaxsafeforcnos_5" || return
  assert_contains "$last_output" "qaxsafecheckui_5" || return
  assert_contains "$last_output" "renamed-client" || return
  assert_contains "$last_output" "first-command" || return
  assert_contains "$last_output" "AtRuStAgEnT" || return
  [[ "$last_output" != *"unrelated"* ]] || fail "matched a non-command argument under /opt/qaxsafe"
}

test_runtime_override_only_for_protected_qianxin_unit() {
  new_case
  printf '%s\n' serviceqaxsafe.service aTrustDaemon.service >"$FAKE_STATE/system_units"
  printf '%s\n' serviceqaxsafe.service aTrustDaemon.service >"$FAKE_STATE/active_system_units"
  printf '%s\n' serviceqaxsafe.service aTrustDaemon.service >"$FAKE_STATE/refuse_units"

  run_script stop --yes --no-processes --no-proxy-clean

  assert_status 0 || return
  [[ "$(<"$FAKE_STATE/overridden_units")" == "serviceqaxsafe.service" ]] ||
    fail "runtime override was not limited to serviceqaxsafe.service" || return
  ! command grep -Fxq serviceqaxsafe.service "$FAKE_STATE/active_system_units" ||
    fail "protected QiAnXin unit remained active" || return
  command grep -Fxq aTrustDaemon.service "$FAKE_STATE/active_system_units" ||
    fail "test fixture unexpectedly stopped protected aTrust unit" || return
  assert_file_contains "$FAKE_STATE/log" "sudo tee /run/systemd/system/serviceqaxsafe.service.d/90-clear-trust-agents.conf" || return
  assert_before "$(<"$FAKE_STATE/log")" \
    "systemctl daemon-reload" "systemctl stop serviceqaxsafe.service" || return
}

test_dry_run_prints_complete_plan_without_side_effects() {
  new_case
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/system_units"
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/active_system_units"
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/refuse_units"
  command cat >"$FAKE_STATE/ps.default" <<'EOF'
  201 root future-daemon /opt/qaxsafe/future-daemon /opt/qaxsafe/future-daemon
EOF

  run_script stop --dry-run --yes --no-proxy-clean

  assert_status 0 || return
  [[ "$(<"$FAKE_STATE/active_system_units")" == "serviceqaxsafe.service" ]] ||
    fail "dry-run changed service state" || return
  [[ ! -s "$FAKE_STATE/overridden_units" ]] || fail "dry-run installed a runtime override" || return
  assert_contains "$last_output" "+ sudo mkdir -p /run/systemd/system/serviceqaxsafe.service.d" || return
  assert_contains "$last_output" "+ sudo tee /run/systemd/system/serviceqaxsafe.service.d/90-clear-trust-agents.conf" || return
  assert_contains "$last_output" "+ sudo systemctl daemon-reload" || return
  assert_contains "$last_output" "+ sudo systemctl stop serviceqaxsafe.service" || return
  assert_contains "$last_output" "+ sudo kill -KILL 201" || return
  assert_file_not_contains "$FAKE_STATE/log" "sudo kill" || return
}

test_sourced_dry_run_preserves_proxy_environment() {
  new_case
  set +e
  last_output=$(HTTP_PROXY=http://proxy.invalid HTTPS_PROXY=https://proxy.invalid \
    bash -c 'source "$1" stop --dry-run --yes --no-services --no-processes; printf "HTTP_PROXY=%s\nHTTPS_PROXY=%s\n" "${HTTP_PROXY-unset}" "${HTTPS_PROXY-unset}"' \
      _ "$script" 2>&1)
  last_status=$?
  set -e

  assert_status 0 || return
  assert_contains "$last_output" "HTTP_PROXY=http://proxy.invalid" || return
  assert_contains "$last_output" "HTTPS_PROXY=https://proxy.invalid" || return
}

test_qianxin_kills_in_batches_and_rescans_respawns() {
  new_case
  command cat >"$FAKE_STATE/ps.1" <<'EOF'
  301 root daemon-a /opt/qaxsafe/daemon-a /opt/qaxsafe/daemon-a
  302 nc tray-a /opt/qaxsafe/tray-a /opt/qaxsafe/tray-a
EOF
  command cp "$FAKE_STATE/ps.1" "$FAKE_STATE/ps.2"
  command cat >"$FAKE_STATE/ps.3" <<'EOF'
  303 nc respawned /opt/qaxsafe/respawned /opt/qaxsafe/respawned
EOF
  : >"$FAKE_STATE/ps.4"

  run_script stop --yes --no-services --no-proxy-clean

  assert_status 0 || return
  assert_file_contains "$FAKE_STATE/log" "sudo kill -KILL 301 302" || return
  assert_file_contains "$FAKE_STATE/log" "sudo kill -KILL 303" || return
  assert_file_count "$FAKE_STATE/log" "sudo kill -KILL" 2 || return
}

test_qianxin_fails_after_three_kill_rounds() {
  new_case
  command cat >"$FAKE_STATE/ps.1" <<'EOF'
  401 root daemon /opt/qaxsafe/daemon /opt/qaxsafe/daemon
EOF
  command cp "$FAKE_STATE/ps.1" "$FAKE_STATE/ps.2"
  command cat >"$FAKE_STATE/ps.3" <<'EOF'
  402 root daemon /opt/qaxsafe/daemon /opt/qaxsafe/daemon
EOF
  command cat >"$FAKE_STATE/ps.4" <<'EOF'
  403 root daemon /opt/qaxsafe/daemon /opt/qaxsafe/daemon
EOF
  command cat >"$FAKE_STATE/ps.5" <<'EOF'
  404 root daemon /opt/qaxsafe/daemon /opt/qaxsafe/daemon
EOF

  run_script stop --yes --no-services --no-proxy-clean

  assert_status 1 || return
  assert_file_count "$FAKE_STATE/log" "sudo kill -KILL" 3 || return
  assert_contains "$last_output" "404 root daemon" || return
}

test_stop_still_kills_processes_when_service_stop_fails() {
  new_case
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/system_units"
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/active_system_units"
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/unstoppable_units"
  command cat >"$FAKE_STATE/ps.1" <<'EOF'
  451 root daemon /opt/qaxsafe/daemon /opt/qaxsafe/daemon
EOF
  command cp "$FAKE_STATE/ps.1" "$FAKE_STATE/ps.2"
  : >"$FAKE_STATE/ps.3"

  run_script stop --yes --no-proxy-clean

  assert_status 1 || return
  assert_file_contains "$FAKE_STATE/log" "sudo kill -KILL 451" || return
  assert_contains "$last_output" "QiAnXin system services are still active" || return
}

test_other_products_keep_term_and_force_semantics() {
  local parent_pid="$$"
  new_case
  printf '  %s nc aTrustAgent /opt/atrust/aTrustAgent /opt/atrust/aTrustAgent\n' \
    "$parent_pid" >"$FAKE_STATE/ps.default"

  run_script stop --yes --no-services --no-proxy-clean

  assert_status 1 || return
  assert_file_contains "$FAKE_STATE/log" "sudo kill -TERM $parent_pid" || return
  assert_file_not_contains "$FAKE_STATE/log" "sudo kill -KILL $parent_pid" || return

  new_case
  printf '  %s nc SangforTray /opt/sangfor/SangforTray /opt/sangfor/SangforTray\n' \
    "$parent_pid" >"$FAKE_STATE/ps.default"

  run_script stop --yes --force --no-services --no-proxy-clean

  assert_status 0 || return
  assert_file_contains "$FAKE_STATE/log" "sudo kill -TERM $parent_pid" || return
  assert_file_contains "$FAKE_STATE/log" "sudo kill -KILL $parent_pid" || return
}

test_restart_starts_system_before_autostart_and_verifies_recovery() {
  new_case
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/system_units"
  printf '%s\n' app-autostartqax@autostart.service >"$FAKE_STATE/user_units"
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/active_system_units"
  printf '%s\n' app-autostartqax@autostart.service >"$FAKE_STATE/active_user_units"
  command cat >"$FAKE_STATE/ps.1" <<'EOF'
  501 root daemon /opt/qaxsafe/daemon /opt/qaxsafe/daemon
  502 nc tray /opt/qaxsafe/tray /opt/qaxsafe/tray
EOF
  command cp "$FAKE_STATE/ps.1" "$FAKE_STATE/ps.2"
  : >"$FAKE_STATE/ps.3"
  command cat >"$FAKE_STATE/ps.4" <<'EOF'
  503 root qaxsafed /opt/qaxsafe/qaxsafed /opt/qaxsafe/qaxsafed
  504 nc qaxtray_5 /opt/qaxsafe/qaxtray_5 /opt/qaxsafe/qaxtray_5
EOF

  run_script restart --yes --no-proxy-clean

  assert_status 0 || return
  assert_before "$(<"$FAKE_STATE/log")" \
    "systemctl start serviceqaxsafe.service" \
    "systemctl --user start app-autostartqax@autostart.service" || return
  assert_contains "$last_output" "QiAnXin daemon and tray processes are running." || return
}

test_start_fails_when_qianxin_processes_do_not_recover() {
  new_case
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/system_units"
  printf '%s\n' app-startqax@autostart.service >"$FAKE_STATE/user_units"
  : >"$FAKE_STATE/ps.default"

  run_script start --no-proxy-clean

  assert_status 1 || return
  assert_contains "$last_output" "QiAnXin daemon process did not recover" || return
  assert_contains "$last_output" "QiAnXin tray process did not recover" || return
}

test_start_rejects_helpers_as_daemon_and_tray() {
  new_case
  printf '%s\n' serviceqaxsafe.service >"$FAKE_STATE/system_units"
  printf '%s\n' app-startqax@autostart.service >"$FAKE_STATE/user_units"
  command cat >"$FAKE_STATE/ps.default" <<'EOF'
  601 root qaxtqdown /opt/qaxsafe/tools/qaxtqdown /opt/qaxsafe/tools/qaxtqdown
  602 nc qaxsafecheckui_ /opt/qaxsafe/safecheck/qaxsafecheckui_5 /opt/qaxsafe/safecheck/qaxsafecheckui_5
EOF

  run_script start --no-proxy-clean

  assert_status 1 || return
  assert_contains "$last_output" "QiAnXin daemon process did not recover" || return
  assert_contains "$last_output" "QiAnXin tray process did not recover" || return
}

run_test() {
  local name="$1"
  shift
  tests_run=$((tests_run + 1))
  printf 'TEST %s\n' "$name"
  if "$@"; then
    printf '  PASS\n'
  else
    tests_failed=$((tests_failed + 1))
    printf '  FAIL\n'
  fi
}

run_test "status matches executable and command paths under /opt/qaxsafe" test_status_matches_all_qianxin_paths
run_test "runtime override is limited to protected QiAnXin units" test_runtime_override_only_for_protected_qianxin_unit
run_test "dry-run prints all actions without side effects" test_dry_run_prints_complete_plan_without_side_effects
run_test "sourced dry-run preserves proxy variables" test_sourced_dry_run_preserves_proxy_environment
run_test "QiAnXin processes are killed in batches and rescanned" test_qianxin_kills_in_batches_and_rescans_respawns
run_test "QiAnXin cleanup fails after three kill rounds" test_qianxin_fails_after_three_kill_rounds
run_test "process cleanup continues after a service stop failure" test_stop_still_kills_processes_when_service_stop_fails
run_test "aTrust and Sangfor retain TERM and force semantics" test_other_products_keep_term_and_force_semantics
run_test "restart starts system service before autostart and verifies recovery" test_restart_starts_system_before_autostart_and_verifies_recovery
run_test "start fails when QiAnXin processes do not recover" test_start_fails_when_qianxin_processes_do_not_recover
run_test "start does not mistake helpers for daemon and tray" test_start_rejects_helpers_as_daemon_and_tray

printf '\n%d tests, %d failures\n' "$tests_run" "$tests_failed"
((tests_failed == 0))
