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
  local expr
  expr="$(join_ere "${process_patterns[@]}")"

  ps -eo pid=,user=,comm=,args= |
    awk -v me="$self_pid" '$1 != me { print }' |
    grep -E -i "$expr" |
    grep -v -E '(^|[[:space:]])(grep|awk|systemctl|sudo|clear_trust_agents\.sh)([[:space:]]|$)' || true
}

is_qianxin_kill_target() {
  local target="$1"

  [[ "$target" =~ (^|[[:space:]/])(qaxsafed|qaxtqdown)([[:space:]]|$) ]]
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
  local user_units system_units unit

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
      run_or_print sudo systemctl stop "$unit" || true
    done <<<"$system_units"
  fi
}

start_services() {
  local user_units system_units unit

  [[ "$manage_services" -eq 1 ]] || return 0

  user_units="$(matching_units user)"
  system_units="$(matching_units system)"

  if [[ -z "$user_units" && -z "$system_units" ]]; then
    echo "No matching systemd services found to start."
    return 0
  fi

  if [[ -n "$user_units" ]]; then
    echo "Starting matching user services:"
    printf '%s\n' "$user_units"
    while read -r unit; do
      [[ -z "$unit" ]] && continue
      run_or_print systemctl --user start "$unit" || true
    done <<<"$user_units"
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
      run_or_print sudo systemctl start "$unit" || true
    done <<<"$system_units"
  fi
}

terminate_processes() {
  local targets term_pids kill_pids alive_pids pid line

  [[ "$manage_processes" -eq 1 ]] || return 0

  targets="$(find_targets)"
  if [[ -z "$targets" ]]; then
    echo "No matching aTrust/QiAnXin/Sangfor processes found."
    return 0
  fi

  echo "Terminating matching processes:"
  printf '%s\n' "$targets"
  term_pids=""
  kill_pids=""

  while read -r line; do
    [[ -z "$line" ]] && continue
    read -r pid _ <<<"$line"
    [[ -z "$pid" ]] && continue

    if is_qianxin_kill_target "$line"; then
      kill_pids="${kill_pids}${pid}"$'\n'
    else
      term_pids="${term_pids}${pid}"$'\n'
    fi
  done <<<"$targets"

  if [[ -n "$kill_pids" ]]; then
    echo "Sending SIGKILL to QiAnXin protected processes:"
    printf '%s\n' "$kill_pids"
    while read -r pid; do
      [[ -z "$pid" ]] && continue
      run_or_print sudo kill -KILL "$pid" || true
    done <<<"$kill_pids"
  fi

  if [[ -n "$term_pids" ]]; then
    echo "Sending SIGTERM to remaining matched processes:"
    printf '%s\n' "$term_pids"
    while read -r pid; do
      [[ -z "$pid" ]] && continue
      run_or_print sudo kill -TERM "$pid" || true
    done <<<"$term_pids"
  fi

  [[ "$dry_run" -eq 1 ]] && return 0
  [[ -n "$term_pids" ]] || return 0

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
    echo "Matched processes terminated."
  fi
}

stop_all() {
  show_status
  confirm_destructive_action "Stop matching services and terminate matching processes?" || return 1
  stop_services
  terminate_processes
}

restart_all() {
  show_status
  confirm_destructive_action "Restart matching services and terminate matching processes first?" || return 1
  stop_services
  terminate_processes
  start_services
}

if [[ "$clean_proxy" -eq 1 ]]; then
  clear_proxy_env
  echo "Proxy variables cleared in this script process."
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
