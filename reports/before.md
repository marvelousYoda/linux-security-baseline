# Security Baseline Report

- **Host:** TemboLove
- **OS:** Ubuntu 26.04.1 LTS
- **Kernel:** 7.0.0-38-generic
- **Date:** 2026-10-24 17:14 EDT

## 1. Pending updates

- Packages with updates available: 0
- Of those, security updates: 0

**Result: ✅ PASS** - no pending security updates.

## 2. Firewall (ufw)

- Status: inactive

**Result: ⚠️ WARN** - the firewall is off. Fix: sudo ufw enable

## 3. Listening network ports

Programs waiting for network connections, grouped by who can reach them:

- 🔴 **Exposed:** listens on all addresses (0.0.0.0, [::] or *), so other machines can connect
- 🟡 **Local network:** listens on one specific network address (including multicast and link-local)
- 🟢 **Local only:** listens on localhost, so only this machine can connect

| Status | Proto | Address | Port | Program | PID |
| --- | --- | --- | --- | --- | --- |
| 🔴 Exposed | udp | `*` | 59489 | python3 | 3930 |
| 🔴 Exposed | udp | `0.0.0.0` | 36786 | python3 | 3930 |
| 🔴 Exposed | udp | `0.0.0.0` | 5353 | avahi-daemon | 925 |
| 🔴 Exposed | udp | `[::]` | 5353 | avahi-daemon | 925 |
| 🟡 Local network | udp | `10.0.2.15` | 3702 | python3 | 3930 |
| 🟡 Local network | udp | `239.255.255.250` | 3702 | python3 | 3930 |
| 🟡 Local network | udp | `[fe80::a00:27ff:fec3:884d]%enp0s8` | 3702 | python3 | 3930 |
| 🟡 Local network | udp | `[ff02::c]%enp0s8` | 3702 | python3 | 3930 |
| 🟢 Local only | tcp | `127.0.0.1` | 631 | cupsd | 1279 |
| 🟢 Local only | tcp | `127.0.0.53%lo` | 53 | systemd-resolve | 369 |
| 🟢 Local only | tcp | `127.0.0.54` | 53 | systemd-resolve | 369 |
| 🟢 Local only | tcp | `[::1]` | 631 | cupsd | 1279 |
| 🟢 Local only | udp | `127.0.0.1` | 323 | chronyd | 1089 |
| 🟢 Local only | udp | `127.0.0.53%lo` | 53 | systemd-resolve | 369 |
| 🟢 Local only | udp | `127.0.0.54` | 53 | systemd-resolve | 369 |
| 🟢 Local only | udp | `[::1]` | 323 | chronyd | 1089 |

### Flagged ports

Ports reachable from other machines. For each one: find out what it is,
decide whether you need it, and disable it or block it with the firewall.

- 🔴 **python3** on udp port **59489** (address `*`). Investigate: `ps -fp 3930`
- 🔴 **python3** on udp port **36786** (address `0.0.0.0`). Investigate: `ps -fp 3930`
- 🔴 **avahi-daemon** on udp port **5353** (address `0.0.0.0`). Investigate: `ps -fp 925`
- 🔴 **avahi-daemon** on udp port **5353** (address `[::]`). Investigate: `ps -fp 925`

**Result: ⚠️ WARN** - 4 port(s) listen on all addresses (see Flagged ports). Check each one is needed; the firewall should block the rest.

## Summary

- ✅ Passed: 1
- ⚠️ Warnings: 2
