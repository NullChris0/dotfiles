#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: clear_trust_agents.sh [stop|start|restart|status] [options]

Aggressively stop, start, restart, or inspect aTrust and QiAnXin/Sangfor
client services and processes.

Actions:
  stop       Stop matching systemd services, then terminate matching processes.
             This is the default action.
  start      Start matching installed systemd services.
  restart    Stop matching services/processes, then start matching services.
  status     Show matching services and processes.

Options:
  -n, --dry-run          Show commands without changing services/processes.
  -y, --yes              Do not prompt before stop/restart actions.
  -f, --force            Send SIGKILL to processes still alive after SIGTERM.
  --no-proxy-clean       Do not clear proxy variables in this script process.
  --no-services          Do not run systemctl commands.
  --no-processes         Do not kill processes.
  --no-kill              Only clear proxy variables; do not inspect or kill.
  -h, --help             Show this help.

Examples:
  ~/clear_trust_agents.sh --dry-run
  ~/clear_trust_agents.sh stop --yes --force
  ~/clear_trust_agents.sh restart --yes --force
  ~/clear_trust_agents.sh start
  ~/clear_trust_agents.sh status

Notes:
  System services are controlled with sudo systemctl when needed.
  This script does not disable, mask, uninstall, remove files, or edit startup.
  To clear proxy variables in your current shell, run:
    source ~/clear_trust_agents.sh --no-kill
EOF
}

action="stop"
dry_run=0
assume_yes=0
force=0
clean_proxy=1
manage_services=1
manage_processes=1
no_kill=0

if (($# > 0)); then
  case "$1" in
    stop|start|restart|status)
      action="$1"
      shift
      ;;
  esac
fi

while (($#)); do
  case "$1" in
    -n|--dry-run) dry_run=1 ;;
    -y|--yes) assume_yes=1 ;;
    -f|--force) force=1 ;;
    --no-proxy-clean) clean_proxy=0 ;;
    --no-services) manage_services=0 ;;
    --no-processes) manage_processes=0 ;;
    --no-kill) no_kill=1 ;;
    -h|--help) usage; return 0 2>/dev/null || exit 0 ;;
    *) echo "Unknown option/action: $1" >&2; usage >&2; return 2 2>/dev/null || exit 2 ;;
  esac
  shift
done

case "$action" in
  stop|start|restart|status) ;;
  *) echo "Unsupported action: $action" >&2; return 2 2>/dev/null || exit 2 ;;
esac

current_user="$(id -un)"
self_pid="$$"

service_patterns=(
  'atrust'
  'aTrust'
  'sangfor'
  'Sangfor'
  'sfvpn'
  'svpn'
  'qianxin'
  'QiAnXin'
  'qax'
  'QAX'
  'tianqing'
  'Tianqing'
  'skylar'
  'Skylar'
  'xagt'
  'qaxsafe'
  'qaxvpn'
  '奇安信'
)

process_patterns=(
  '(^|[[:space:]/])(aTrust|atrust|aTrustAgent|atrustagent|aTrustTray|aTrustClient)([[:space:]]|$)'
  '(^|[[:space:]/])(Sangfor|sangfor|sfvpn|svpn|SangforCSClient|SangforPromoteService|SangforTray)([[:space:]]|$)'
  '(^|[[:space:]/])(qaxtray|qaxagent|qaxbrowser|QAXTray|QAXAgent|qaxservice|QAXService)([[:space:]]|$)'
  '(^|[[:space:]/])(Tianqing|tianqing|Skylar|skylar|xagt|XAgent|qaxsafe|qaxvpn|qaxsafed|qaxtqdown)([[:space:]]|$)'
  '奇安信'
)

clear_proxy_env() {
  unset http_proxy https_proxy no_proxy all_proxy
  unset HTTP_PROXY HTTPS_PROXY NO_PROXY ALL_PROXY
  unset ftp_proxy FTP_PROXY ws_proxy wss_proxy WS_PROXY WSS_PROXY
}

join_ere() {
  local joined=""
  local pattern
  for pattern in "$@"; do
    if [[ -z "$joined" ]]; then
      joined="$pattern"
    else
      joined="$joined|$pattern"
    fi
  done
  printf '%s' "$joined"
}

matches_process_pattern() {
  local target="$1" expr="$2" restore_nocasematch=0 result=1

  if ! shopt -q nocasematch; then
    shopt -s nocasematch
    restore_nocasematch=1
  fi
  [[ "$target" =~ $expr ]] && result=0
  ((restore_nocasematch == 0)) || shopt -u nocasematch
  return "$result"
}

run_or_print() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'

  if [[ "$dry_run" -eq 1 ]]; then
    return 0
  fi

  "$@"
}

have_systemctl() {
  command -v systemctl >/dev/null 2>&1
}

have_sudo() {
  command -v sudo >/dev/null 2>&1
}

list_user_units() {
  have_systemctl || return 0
  systemctl --user list-unit-files --type=service --no-legend --no-pager 2>/dev/null | awk '{print $1}' || true
  systemctl --user list-units --type=service --all --no-legend --no-pager 2>/dev/null | awk '{print $1}' || true
}

list_system_units() {
  have_systemctl || return 0
  systemctl list-unit-files --type=service --no-legend --no-pager 2>/dev/null | awk '{print $1}' || true
  systemctl list-units --type=service --all --no-legend --no-pager 2>/dev/null | awk '{print $1}' || true
}

matching_units() {
  local scope="$1"
  local expr
  expr="$(join_ere "${service_patterns[@]}")"

  case "$scope" in
    user) list_user_units ;;
    system) list_system_units ;;
    *) return 2 ;;
  esac |
    grep -E -i "$expr" |
    grep -v -E '@\.service$' |
    sort -u || true
}

find_targets() {
  local expr line pid owner command executable arguments
  expr="$(join_ere "${process_patterns[@]}")"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    read -r pid owner command executable arguments <<<"$line"
    [[ "$pid" == "$self_pid" ]] && continue
    case "$command" in
      grep|awk|systemctl|sudo|clear_trust_agents.sh) continue ;;
    esac

    if is_qianxin_kill_target "$line" || matches_process_pattern "$line" "$expr"; then
      printf '%s\n' "$line"
    fi
  done < <(ps -eo pid=,user=,comm=,exe=,args=)
}

is_qianxin_kill_target() {
  local target="$1" pid owner command executable arguments command_path

  read -r pid owner command executable arguments <<<"$target"
  read -r command_path _ <<<"$arguments"

  [[ "$executable" == /opt/qaxsafe/* || "$command_path" == /opt/qaxsafe/* ]]
}

find_qianxin_targets() {
  local line

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    is_qianxin_kill_target "$line" && printf '%s\n' "$line"
  done < <(find_targets)
}

target_pids() {
  local line pid

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    read -r pid _ <<<"$line"
    [[ -z "$pid" ]] || printf '%s\n' "$pid"
  done
}

qianxin_process_role() {
  local target="$1" pid owner command executable arguments command_path process_path basename

  read -r pid owner command executable arguments <<<"$target"
  read -r command_path _ <<<"$arguments"
  if [[ "$command_path" == /opt/qaxsafe/* ]]; then
    process_path="$command_path"
  else
    process_path="$executable"
  fi
  basename="${process_path##*/}"
  basename="${basename,,}"

  if [[ "$owner" == root && "$basename" =~ ^qaxsafed(_[[:digit:]]+)?$ ]]; then
    printf 'daemon\n'
  elif [[ "$owner" == "$current_user" && "$basename" =~ ^qaxtray(_[[:digit:]]+)?$ ]]; then
    printf 'tray\n'
  fi
}

is_qianxin_unit() {
  local unit="${1,,}"

  [[ "$unit" =~ qianxin|qax|tianqing|skylar|xagt|奇安信 ]]
}

install_qianxin_stop_override() {
  local unit="$1"
  local drop_in_dir="/run/systemd/system/${unit}.d"
  local drop_in_path="$drop_in_dir/90-clear-trust-agents.conf"
  local contents=$'[Unit]\nRefuseManualStop=no\n'

  run_or_print sudo mkdir -p "$drop_in_dir"
  printf '+ sudo tee %q <<EOF\n%sEOF\n' "$drop_in_path" "$contents"
  if [[ "$dry_run" -eq 0 ]]; then
    printf '%s' "$contents" | sudo tee "$drop_in_path" >/dev/null
  fi
}

show_status() {
  local user_units system_units targets

  if [[ "$manage_services" -eq 1 ]]; then
    user_units="$(matching_units user)"
    system_units="$(matching_units system)"

    echo "Matching user services:"
    if [[ -n "$user_units" ]]; then
      printf '%s\n' "$user_units"
    else
      echo "(none)"
    fi

    echo "Matching system services:"
    if [[ -n "$system_units" ]]; then
      printf '%s\n' "$system_units"
    else
      echo "(none)"
    fi
  fi

  if [[ "$manage_processes" -eq 1 ]]; then
    targets="$(find_targets)"
    echo "Matching processes:"
    if [[ -n "$targets" ]]; then
      printf '%s\n' "$targets"
    else
      echo "(none)"
    fi
  fi
}

confirm_destructive_action() {
  local prompt="$1"

  if [[ "$dry_run" -eq 1 || "$assume_yes" -eq 1 ]]; then
    return 0
  fi

  printf '%s [y/N] ' "$prompt"
  read -r answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; return 1 ;;
  esac
}

stop_services() {
  local user_units system_units unit refuse_manual_stop
  local qianxin_units="" override_installed=0 active_qianxin_units=""

  [[ "$manage_services" -eq 1 ]] || return 0

  user_units="$(matching_units user)"
  system_units="$(matching_units system)"

  if [[ -z "$user_units" && -z "$system_units" ]]; then
    echo "No matching systemd services found."
    return 0
  fi

  if [[ -n "$user_units" ]]; then
    echo "Stopping matching user services:"
    printf '%s\n' "$user_units"
    while read -r unit; do
      [[ -z "$unit" ]] && continue
      run_or_print systemctl --user stop "$unit" || true
    done <<<"$user_units"
  fi

  if [[ -n "$system_units" ]]; then
    if ! have_sudo; then
      echo "sudo not found; cannot stop system services." >&2
      return 1
    fi

    echo "Stopping matching system services:"
    printf '%s\n' "$system_units"

    while read -r unit; do
      [[ -z "$unit" ]] && continue
      is_qianxin_unit "$unit" || continue
      qianxin_units="${qianxin_units}${unit}"$'\n'
      refuse_manual_stop="$(systemctl show "$unit" -p RefuseManualStop --value 2>/dev/null || true)"
      if [[ "$refuse_manual_stop" == "yes" ]]; then
        echo "Installing runtime stop override for protected QiAnXin unit: $unit"
        install_qianxin_stop_override "$unit"
        override_installed=1
      fi
    done <<<"$system_units"

    if [[ "$override_installed" -eq 1 ]]; then
      run_or_print sudo systemctl daemon-reload
    fi

    while read -r unit; do
      [[ -z "$unit" ]] && continue
      run_or_print sudo systemctl stop "$unit" || true
    done <<<"$system_units"

    [[ "$dry_run" -eq 0 ]] || return 0
    while read -r unit; do
      [[ -z "$unit" ]] && continue
      if systemctl is-active --quiet "$unit"; then
        active_qianxin_units="${active_qianxin_units}${unit}"$'\n'
      fi
    done <<<"$qianxin_units"

    if [[ -n "$active_qianxin_units" ]]; then
      echo "QiAnXin system services are still active:" >&2
      printf '%s' "$active_qianxin_units" >&2
      return 1
    fi
  fi
}

verify_qianxin_recovery() {
  local qianxin_system_units="$1" qianxin_user_units="$2"
  local unit targets line role
  local daemon_required=0 tray_required=0 daemon_running=0 tray_running=0
  local services_active=1 attempt

  [[ -n "$qianxin_system_units" ]] && daemon_required=1
  [[ -n "$qianxin_user_units" ]] && tray_required=1
  ((daemon_required == 1 || tray_required == 1)) || return 0

  while IFS= read -r unit; do
    [[ -z "$unit" ]] && continue
    if ! systemctl is-active --quiet "$unit"; then
      echo "QiAnXin system service did not become active: $unit" >&2
      services_active=0
    fi
  done <<<"$qianxin_system_units"

  for attempt in 1 2 3 4 5; do
    targets="$(find_qianxin_targets)"
    daemon_running=0
    tray_running=0
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      role="$(qianxin_process_role "$line")"
      [[ "$role" == daemon ]] && daemon_running=1
      [[ "$role" == tray ]] && tray_running=1
    done <<<"$targets"

    if ((daemon_required == 0 || daemon_running == 1)) &&
      ((tray_required == 0 || tray_running == 1)); then
      break
    fi
    ((attempt == 5)) || sleep 1
  done

  if ((daemon_required == 1 && daemon_running == 0)); then
    echo "QiAnXin daemon process did not recover." >&2
    services_active=0
  fi
  if ((tray_required == 1 && tray_running == 0)); then
    echo "QiAnXin tray process did not recover." >&2
    services_active=0
  fi

  if ((services_active == 1)); then
    if ((daemon_required == 1 && tray_required == 1)); then
      echo "QiAnXin daemon and tray processes are running."
    elif ((daemon_required == 1)); then
      echo "QiAnXin daemon process is running."
    else
      echo "QiAnXin tray process is running."
    fi
    return 0
  fi
  return 1
}

start_services() {
  local user_units system_units unit
  local qianxin_user_units="" qianxin_system_units=""

  [[ "$manage_services" -eq 1 ]] || return 0

  user_units="$(matching_units user)"
  system_units="$(matching_units system)"

  if [[ -z "$user_units" && -z "$system_units" ]]; then
    echo "No matching systemd services found to start."
    return 0
  fi

  if [[ -n "$system_units" ]]; then
    if ! have_sudo; then
      echo "sudo not found; cannot start system services." >&2
      return 1
    fi

    echo "Starting matching system services:"
    printf '%s\n' "$system_units"
    while read -r unit; do
      [[ -z "$unit" ]] && continue
      if is_qianxin_unit "$unit"; then
        qianxin_system_units="${qianxin_system_units}${unit}"$'\n'
      fi
      run_or_print sudo systemctl start "$unit" || true
    done <<<"$system_units"
  fi

  if [[ -n "$user_units" ]]; then
    echo "Starting matching user services:"
    printf '%s\n' "$user_units"
    while read -r unit; do
      [[ -z "$unit" ]] && continue
      if is_qianxin_unit "$unit"; then
        qianxin_user_units="${qianxin_user_units}${unit}"$'\n'
      fi
      run_or_print systemctl --user start "$unit" || true
    done <<<"$user_units"
  fi

  [[ "$dry_run" -eq 0 ]] || return 0
  verify_qianxin_recovery "$qianxin_system_units" "$qianxin_user_units"
}

kill_qianxin_processes() {
  local targets="$1" round
  local -a pids=()

  for round in 1 2 3; do
    mapfile -t pids < <(target_pids <<<"$targets")
    ((${#pids[@]} > 0)) || return 0

    echo "Sending SIGKILL to QiAnXin processes (round $round/3):"
    printf '%s\n' "${pids[@]}"
    run_or_print sudo kill -KILL "${pids[@]}" || true

    [[ "$dry_run" -eq 0 ]] || return 0
    sleep 1
    targets="$(find_qianxin_targets)"
    [[ -n "$targets" ]] || {
      echo "QiAnXin processes terminated."
      return 0
    }
  done

  echo "QiAnXin processes are still running after three SIGKILL rounds:" >&2
  printf '%s\n' "$targets" >&2
  return 1
}

terminate_other_processes() {
  local targets="$1" term_pids alive_pids pid line

  [[ -n "$targets" ]] || return 0

  term_pids="$(target_pids <<<"$targets")"
  echo "Sending SIGTERM to remaining matched processes:"
  printf '%s\n' "$term_pids"
  while read -r pid; do
    [[ -z "$pid" ]] && continue
    run_or_print sudo kill -TERM "$pid" || true
  done <<<"$term_pids"

  [[ "$dry_run" -eq 0 ]] || return 0
  sleep 2

  alive_pids=""
  while read -r pid; do
    [[ -z "$pid" ]] && continue
    if kill -0 "$pid" 2>/dev/null; then
      alive_pids="${alive_pids}${pid}"$'\n'
    fi
  done <<<"$term_pids"

  if [[ -n "$alive_pids" ]]; then
    if [[ "$force" -eq 1 ]]; then
      echo "Sending SIGKILL to remaining matched processes:"
      printf '%s\n' "$alive_pids"
      while read -r pid; do
        [[ -z "$pid" ]] && continue
        run_or_print sudo kill -KILL "$pid" || true
      done <<<"$alive_pids"
    else
      echo "Some processes are still alive. Re-run with --force if you intend to kill them:"
      printf '%s\n' "$alive_pids"
      return 1
    fi
  else
    echo "Matched non-QiAnXin processes terminated."
  fi
}

terminate_processes() {
  local targets qianxin_targets="" other_targets="" line result=0

  [[ "$manage_processes" -eq 1 ]] || return 0

  targets="$(find_targets)"
  if [[ -z "$targets" ]]; then
    echo "No matching aTrust/QiAnXin/Sangfor processes found."
    return 0
  fi

  echo "Terminating matching processes:"
  printf '%s\n' "$targets"

  while read -r line; do
    [[ -z "$line" ]] && continue
    if is_qianxin_kill_target "$line"; then
      qianxin_targets="${qianxin_targets}${line}"$'\n'
    else
      other_targets="${other_targets}${line}"$'\n'
    fi
  done <<<"$targets"

  if [[ -n "$qianxin_targets" ]]; then
    kill_qianxin_processes "$qianxin_targets" || result=1
  fi
  if [[ -n "$other_targets" ]]; then
    terminate_other_processes "$other_targets" || result=1
  fi

  return "$result"
}

stop_all() {
  local result=0

  show_status
  confirm_destructive_action "Stop matching services and terminate matching processes?" || return 1
  stop_services || result=1
  terminate_processes || result=1
  return "$result"
}

restart_all() {
  local cleanup_result=0

  show_status
  confirm_destructive_action "Restart matching services and terminate matching processes first?" || return 1
  stop_services || cleanup_result=1
  terminate_processes || cleanup_result=1
  ((cleanup_result == 0)) || return 1
  start_services
}

if [[ "$clean_proxy" -eq 1 ]]; then
  if [[ "$dry_run" -eq 1 ]]; then
    echo "+ unset proxy variables in this script process"
  else
    clear_proxy_env
    echo "Proxy variables cleared in this script process."
  fi
fi

if [[ "$no_kill" -eq 1 ]]; then
  echo "Process/service actions skipped because --no-kill was set."
  return 0 2>/dev/null || exit 0
fi

case "$action" in
  status) show_status ;;
  stop) stop_all ;;
  start) start_services ;;
  restart) restart_all ;;
esac
