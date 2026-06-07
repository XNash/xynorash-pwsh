# XYNORASH PowerShell

A gamer/developer/hacker terminal environment for Windows PowerShell 7 and Windows Terminal.

## What's inside

- **3-line cockpit prompt** — context line, vitals line, input line
- **XYNORASH color palette** — neon cyan, magenta, amber, green on near-black
- **Live system vitals** — CPU%, RAM%, disk usage, uptime, IP, process count
- **Git status** — branch, ahead/behind, staged/modified/untracked/stash
- **Transient prompt** — full cockpit collapses to `❯` after Enter for clean history
- **Admin + SSH indicators** — shown only when relevant
- **Carapace completions** — annotated flag/subcommand completions for 1000+ CLI tools
- **Language runtimes** — auto-detected: Rust, Go, Python, Node, Java, .NET, Flutter, and more
- **Fastfetch** — system info with custom ASCII art on every new tab
- **JetBrainsMono Nerd Font** — auto-installed

## Quick start

```powershell
# Allow script execution (once per machine)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Clone and run
git clone https://github.com/XNash/xynorash-pwsh.git
cd xynorash-pwsh
.\install.ps1
```

Open a new PowerShell tab. Done.

## Requirements

- Windows 10/11
- PowerShell 7+ (`winget install Microsoft.PowerShell`)
- Windows Terminal (recommended — `winget install Microsoft.WindowsTerminal`)
- winget (ships with Windows 11; [install on Windows 10](https://github.com/microsoft/winget-cli/releases))

`install.ps1` handles everything else automatically.

## What `install.ps1` installs

| Tool | Purpose |
|------|---------|
| [oh-my-posh](https://ohmyposh.dev) | Prompt engine |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info on startup |
| [carapace](https://carapace.sh) | Annotated tab completions |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` replacement |
| Terminal-Icons | File/folder icons in listings |
| PSReadLine | Enhanced readline with predictions |
| JetBrainsMono NF | Nerd Font with all icons |

## Layout

```
╭─ 󰍲 user@host ~/path/here ▸  main ~2 +1 ▸
│  󰍛 12% ▸ 󰘚 47% ▸ 󰋊 C:48% ▸ 󰋊 F:27% ▸ ⬆ 1d 4h ▸ 󰩟 192.168.1.x ▸ 󰄹 312 ▸
╰─ Mon 07 Jun  23:41 ❯
```

Line 1 — identity and location  
Line 2 — system vitals (always visible)  
Line 3 — execution time, clock, prompt symbol

## Portability

All config files live in the PowerShell profile directory (`$PROFILE` parent). The setup is self-contained — no system-wide changes beyond winget packages and font registration.

To move to a new machine: clone, run `install.ps1`.
