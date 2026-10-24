# Security Baseline Report

- **Host:** TemboLove
- **OS:** Ubuntu 26.04.1 LTS
- **Kernel:** 7.0.0-38-generic
- **Date:** 2026-10-24 17:29 EDT

## 1. Pending updates

- Packages with updates available: 0
- Of those, security updates: 0

**Result: ✅ PASS** - no pending security updates.

## 2. Firewall (ufw)

- Status: active

**Result: ✅ PASS** - the firewall is on.

## 3. Listening network ports

Programs waiting for network connections, grouped by who can reach them:

- 🔴 **Exposed:** listens on all addresses (0.0.0.0, [::] or *), so other machines can connect
- 🟡 **Local network:** listens on one specific network address (including multicast and link-local)
- 🟢 **Local only:** listens on localhost, so only this machine can connect

| Status | Proto | Address | Port | Program | PID |
| --- | --- | --- | --- | --- | --- |
| 🟢 Local only | tcp | `127.0.0.1` | 631 | cupsd | 1279 |
| 🟢 Local only | tcp | `127.0.0.53%lo` | 53 | systemd-resolve | 369 |
| 🟢 Local only | tcp | `127.0.0.54` | 53 | systemd-resolve | 369 |
| 🟢 Local only | tcp | `[::1]` | 631 | cupsd | 1279 |
| 🟢 Local only | udp | `127.0.0.1` | 323 | chronyd | 1089 |
| 🟢 Local only | udp | `127.0.0.53%lo` | 53 | systemd-resolve | 369 |
| 🟢 Local only | udp | `127.0.0.54` | 53 | systemd-resolve | 369 |
| 🟢 Local only | udp | `[::1]` | 323 | chronyd | 1089 |

**Result: ✅ PASS** - nothing is listening on external addresses.

## Summary

- ✅ Passed: 3
- ⚠️ Warnings: 0
