#!/usr/bin/env bash
#
# baseline.sh - a small security baseline check for Ubuntu
#
# Checks:
#   1. Pending updates (and how many are security updates)
#   2. Firewall (ufw) status
#   3. Network ports listening for connections
#
# Usage:
#   sudo ./baseline.sh                      # print the report
#   sudo ./baseline.sh reports/before.md    # print it and save it to a file

set -u

# Some checks need admin rights, so stop early if not run with sudo.
if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo: sudo $0 $*" >&2
  exit 1
fi

OUTFILE="${1:-}"
PASS=0
WARN=0
REPORT=""

# add "text" -> appends one line to the report
add() { REPORT+="$1"$'\n'; }

# result PASS|WARN "message" -> records the outcome of a check
result() {
  if [[ "$1" == "PASS" ]]; then
    PASS=$((PASS + 1))
    add "**Result: ✅ PASS** - $2"
  else
    WARN=$((WARN + 1))
    add "**Result: ⚠️ WARN** - $2"
  fi
  add ""
}

# --- Header -------------------------------------------------------------
add "# Security Baseline Report"
add ""
add "- **Host:** $(hostname)"
add "- **OS:** $(. /etc/os-release && echo "$PRETTY_NAME")"
add "- **Kernel:** $(uname -r)"
add "- **Date:** $(date '+%Y-%m-%d %H:%M %Z')"
add ""

# --- Check 1: pending updates --------------------------------------------
add "## 1. Pending updates"
add ""
apt-get update -qq >/dev/null 2>&1
UPGRADES=$(apt-get -s upgrade 2>/dev/null | grep -c '^Inst')
SECURITY=$(apt-get -s upgrade 2>/dev/null | grep '^Inst' | grep -ci 'security')
add "- Packages with updates available: $UPGRADES"
add "- Of those, security updates: $SECURITY"
add ""
if [[ "$SECURITY" -eq 0 ]]; then
  result PASS "no pending security updates."
else
  result WARN "$SECURITY security update(s) waiting. Fix: sudo apt upgrade"
fi

# --- Check 2: firewall ---------------------------------------------------
add "## 2. Firewall (ufw)"
add ""
if command -v ufw >/dev/null 2>&1; then
  UFW_STATUS=$(ufw status | head -n 1)
  add "- $UFW_STATUS"
  add ""
  if [[ "$UFW_STATUS" == *"Status: active"* ]]; then
    result PASS "the firewall is on."
  else
    result WARN "the firewall is off. Fix: sudo ufw enable"
  fi
else
  add "- ufw is not installed"
  add ""
  result WARN "no firewall tool found. Fix: sudo apt install ufw"
fi

# --- Check 3: listening ports --------------------------------------------
add "## 3. Listening network ports"
add ""
add "Programs waiting for network connections, grouped by who can reach them:"
add ""
add "- 🔴 **Exposed:** listens on all addresses (0.0.0.0, [::] or *), so other machines can connect"
add "- 🟡 **Local network:** listens on one specific network address (including multicast and link-local)"
add "- 🟢 **Local only:** listens on localhost, so only this machine can connect"
add ""
if command -v ss >/dev/null 2>&1; then
  # One table row per listening socket: status, protocol, address, port, program, PID.
  # Sorting puts 🔴 first, then 🟡, then 🟢.
  ROWS=$(ss -tulpnH | awk '
  {
    proto = $1; local = $5; proc = $7
    n = split(local, parts, ":"); port = parts[n]
    addr = substr(local, 1, length(local) - length(port) - 1)
    prog = "-"; pid = "-"
    if (match(proc, /\("[^"]+"/)) prog = substr(proc, RSTART + 2, RLENGTH - 3)
    if (match(proc, /pid=[0-9]+/)) pid = substr(proc, RSTART + 4, RLENGTH - 4)
    if (addr ~ /^(0\.0\.0\.0|\*|\[::\])$/)                    status = "🔴 Exposed"
    else if (addr ~ /^127\./ || addr ~ /^\[::1\]/ || addr ~ /%lo$/) status = "🟢 Local only"
    else                                                      status = "🟡 Local network"
    printf "| %s | %s | `%s` | %s | %s | %s |\n", status, proto, addr, port, prog, pid
  }' | LC_ALL=C sort)

  EXPOSED=$(grep -c '🔴' <<< "$ROWS")

  add "| Status | Proto | Address | Port | Program | PID |"
  add "| --- | --- | --- | --- | --- | --- |"
  add "$ROWS"
  add ""

  if [[ "$EXPOSED" -gt 0 ]]; then
    add "### Flagged ports"
    add ""
    add "Ports reachable from other machines. For each one: find out what it is,"
    add "decide whether you need it, and disable it or block it with the firewall."
    add ""
    while IFS='|' read -r _ _ proto addr port prog pid _; do
      proto=$(xargs <<< "$proto"); addr=$(xargs <<< "${addr//\`/}")
      port=$(xargs <<< "$port");   prog=$(xargs <<< "$prog"); pid=$(xargs <<< "$pid")
      add "- 🔴 **$prog** on $proto port **$port** (address \`$addr\`). Investigate: \`ps -fp $pid\`"
    done < <(grep '🔴' <<< "$ROWS")
    add ""
  fi

  if [[ "$EXPOSED" -eq 0 ]]; then
    result PASS "nothing is listening on external addresses."
  else
    result WARN "$EXPOSED port(s) listen on all addresses (see Flagged ports). Check each one is needed; the firewall should block the rest."
  fi
else
  add "- The ss tool is not installed, so ports could not be checked"
  add ""
  result WARN "could not check ports. Fix: sudo apt install iproute2"
fi

# --- Summary -------------------------------------------------------------
add "## Summary"
add ""
add "- ✅ Passed: $PASS"
add "- ⚠️ Warnings: $WARN"

echo "$REPORT"

if [[ -n "$OUTFILE" ]]; then
  mkdir -p "$(dirname "$OUTFILE")"
  printf '%s' "$REPORT" > "$OUTFILE"
  # Give the file back to your normal user so you can edit and commit it.
  if [[ -n "${SUDO_USER:-}" ]]; then
    chown "$SUDO_USER": "$OUTFILE" "$(dirname "$OUTFILE")"
  fi
  echo "Report saved to $OUTFILE"
fi
