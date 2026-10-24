# Linux Security Baseline

A small Bash script that audits the security of an Ubuntu machine and writes a Markdown report. I built it in my homelab to learn Linux and basic system hardening, then used it to measure the effect of hardening my own VM.

## What it checks

| # | Check | Why it matters |
| --- | --- | --- |
| 1 | Pending security updates | Unpatched software is one of the most common ways systems get compromised |
| 2 | Firewall (ufw) status | A firewall blocks network traffic you didn't intend to allow |
| 3 | Listening network ports | Every open port is a possible way in; anything not needed should be closed |

## How to run it

```bash
git clone https://github.com/<your-username>/linux-security-baseline.git
cd linux-security-baseline
chmod +x baseline.sh
sudo ./baseline.sh reports/before.md
```

It needs `sudo` because reading firewall status and which program owns each port requires admin rights. It only reads settings; it never changes anything.

## How to read the report

Each check ends with a result:

- **✅ PASS**: nothing to do
- **⚠️ WARN**: something worth fixing, with the suggested fix next to it

### Understanding the ports check

Think of the computer as an office building:

- **Ports are numbered doors.** Each service that accepts connections waits behind its own door, for example DNS at door 53 and printing at door 631.
- **"Listening" means someone is behind the door, waiting for a knock.**
- **The address says which entrance the door faces.** Some doors open only onto the inside corridor; others open onto the street, where anyone can knock.

Every door facing the street is a possible way in, so the goal is as few as possible, and only for services you actually need.

### Reading a row of the ports table

| Column | Meaning |
| --- | --- |
| Status | Who can reach this port (see below) |
| Proto | **tcp** works like a phone call (connect, then talk), used for web, SSH and printing. **udp** works like shouting a message across a room, used for DNS, time sync and device discovery |
| Address | Which network address the service listens on, the entrance the door faces |
| Port | The door number |
| Program | The software listening behind the door |
| PID | The process ID, used to look the program up with `ps -fp <PID>` |

### What the status means

| Status | Typical addresses | Who can connect | What to do |
| --- | --- | --- | --- |
| 🔴 Exposed | `0.0.0.0`, `[::]`, `*` | Any machine on any network this computer is connected to | Confirm it's needed; otherwise disable it, and let the firewall block the rest |
| 🟡 Local network | A specific IP such as `10.0.2.15`; multicast such as `239.255.255.250` or `[ff02::c]`; link-local `fe80::…` | Machines on the same local network | Usually fine, but know what it is |
| 🟢 Local only | `127.0.0.1`, `127.0.0.53`, `[::1]`, or anything ending in `%lo` | Only this computer | Nothing to do |

The **Flagged ports** list repeats every 🔴 row, with the command to identify each program.

### Firewall vs. disabling a service

- **Turning on the firewall** is like a security guard at the street entrance who turns away anyone not on the list. The doors still exist, but outside knocks are refused.
- **Disabling a service** is like bricking up the door. Nothing is listening, so there is nothing to knock on.

The ports check counts what is *listening*, so enabling the firewall alone won't clear its warning. Doing both is called **defense in depth**: if a firewall rule is ever misconfigured, the removed service still can't be reached.

### A quick checklist for any report

1. Look for 🔴 rows first.
2. For each one, identify the program: `ps -fp <PID>`.
3. Ask whether you need it. If not, disable it. If you do, make sure the firewall only allows who should reach it.

## My lab

- **Host:** Windows on ARM laptop (Snapdragon X Elite), VirtualBox 7.2
- **VM:** `ubuntu-love`, Ubuntu Desktop 26.04 LTS (arm64)

## Results

| Check | Before | After |
| --- | --- | --- |
| Security updates | ✅ 0 pending | ✅ 0 pending |
| Firewall | ⚠️ Inactive | ✅ Active, default deny incoming |
| Listening ports | ⚠️ 4 exposed (avahi-daemon, wsdd) | ✅ 0 exposed, 8 local only |
| **Score** | **1 of 3 passed** | **3 of 3 passed** |

Full reports: [before](reports/before.md) · [after](reports/after.md)

## What I changed

1. **Turned on the firewall**, which Ubuntu ships disabled:
   ```bash
   sudo ufw enable
   ```
2. **Disabled avahi-daemon**, the mDNS ("Bonjour") service that searches the network for printers and devices. Disabling the service alone wasn't enough, because its socket could still start it again, so I stopped both:
   ```bash
   sudo systemctl disable --now avahi-daemon.service avahi-daemon.socket
   ```
3. **Identified and stopped wsdd.** The report flagged an unnamed `python3` process. Looking it up showed it was wsdd, a Windows network discovery helper started by the Files app:
   ```bash
   ps -fp <PID>    # showed: python3 /usr/bin/wsdd --no-host --discovery ...
   kill <PID>
   ```

## What I learned

- **The address matters more than the port.** The same service can be harmless or exposed depending on where it listens: `127.0.0.1` is reachable only from the machine itself, while `0.0.0.0` or `[::]` is reachable from any network it's connected to. Reading the address column first is the fastest way to find real risk.
- **Never trust a process name at face value.** "python3" told me nothing. `ps -fp <PID>` showed the full command, which turned an unknown program into a specific, explainable one: wsdd, searching for Windows file shares. Investigating before changing anything is a habit worth keeping.
- **Killing a parent doesn't kill its children.** When I stopped wsdd's parent process, wsdd kept running and was adopted by another process (its parent ID changed). I had to stop it directly. It's a small detail, but it's also how unwanted processes can survive a half-finished cleanup.
- **Disabled is not the same as stopped.** systemd disabled avahi from starting at boot but warned that its socket was still active and could wake it up. Checking with `systemctl is-active` confirmed the real state.
- **A firewall and fewer services solve different problems.** The firewall blocks outside connections, but the services were still listening. Turning off what I didn't need removed the exposure entirely. Using both is defense in depth.
- **Secure defaults aren't always the defaults.** A fresh desktop install had its firewall off and two discovery services exposed. They're convenient on a home network, but every default is a product decision with a security trade-off.

## Why this matters for product management

- **Default settings are product decisions.** Ubuntu ships with discovery services on and the firewall off because it favors "it just works" for desktop users. Every product makes the same trade-off between convenience and exposure, and PMs own that call more often than they realize. Secure-by-default is something to choose deliberately, not inherit.
- **It sharpens acceptance criteria.** After this project I can write requirements like "the service listens only on localhost unless explicitly configured" or "new features don't open network ports without a security review", instead of a vague "make it secure."
- **It makes conversations with security teams concrete.** When an engineer says a service is "bound to 0.0.0.0," I now know what that means and can ask the right follow-ups: does it need to be reachable? Who should reach it? What's blocking everyone else?
- **Baseline checks are a product capability.** This script is a tiny version of what compliance tools, cloud security posture tools and CI pipelines run at scale. Understanding how they work helps when evaluating vendors, scoping a security feature, or answering an enterprise customer's security questionnaire.
- **Measuring before and after builds trust.** Turning "we hardened it" into a 1/3 → 3/3 comparison is the same move as reporting on any product metric. Security improvements are easier to prioritize when they're visible and measurable.

## Next steps

- [ ] Add a check for users with admin (sudo) rights
- [ ] Add a check for failed login attempts
- [ ] Add a check for SSH settings (root login, password login)
- [ ] Rerun after a reboot to see whether wsdd comes back when the Files app browses the network
- [ ] Run it against the router VM in week 6 and compare
