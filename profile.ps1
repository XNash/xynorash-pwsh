# User customizations — loaded before Microsoft.PowerShell_profile.ps1
# CTT profile calls Get-Theme_Override if it exists; otherwise falls back to cobalt2.

function Get-Theme_Override {
    $themePath = Join-Path (Split-Path $PROFILE) "xynorash.omp.json"
    if (Test-Path $themePath) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
        Enable-KeyHandlers   # activates transient prompt on Enter
        $global:__xyno_omp = $function:prompt
        $global:__xyno_n   = 0
        $global:__xyno_cpu = [System.Diagnostics.PerformanceCounter]::new('Processor', '% Processor Time', '_Total')
        $null = $global:__xyno_cpu.NextValue()  # seed — first call always returns 0
        $env:XYNO_IS_ADMIN = if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { '1' } else { '' }
        $function:prompt = {
            $global:__xyno_n++
            # CPU — reads interval since last prompt, no WMI, no sleep
            $env:XYNO_CPU = [math]::Round($global:__xyno_cpu.NextValue())
            # Uptime — pure arithmetic, zero cost
            $s = [long]([System.Environment]::TickCount64 / 1000)
            $d = [int]($s / 86400); $h = [int](($s % 86400) / 3600); $m = [int](($s % 3600) / 60)
            $env:XYNO_UPTIME = if ($d -gt 0) { "${d}d ${h}h" } elseif ($h -gt 0) { "${h}h ${m}m" } else { "${m}m" }
            # Process count
            $env:XYNO_PROCS = (Get-Process -ErrorAction SilentlyContinue).Count
            # Disk — refresh every 5 prompts
            if ($global:__xyno_n % 5 -eq 1) {
                $dc = Get-PSDrive C -ErrorAction SilentlyContinue
                if ($dc) { $env:XYNO_DISK_C = [math]::Round($dc.Used / ($dc.Used + $dc.Free) * 100) }
                $df = Get-PSDrive F -ErrorAction SilentlyContinue
                if ($df) { $env:XYNO_DISK_F = [math]::Round($df.Used / ($df.Used + $df.Free) * 100) }
            }
            # IP — refresh every 20 prompts
            if ($global:__xyno_n % 20 -eq 1) {
                try {
                    $env:XYNO_IP = (Get-NetIPAddress -AddressFamily IPv4 -Type Unicast -ErrorAction Stop |
                        Where-Object { $_.IPAddress -notmatch '^(127\.|169\.)' } |
                        Select-Object -First 1).IPAddress
                } catch { $env:XYNO_IP = '?' }
            }
            $r = & $global:__xyno_omp
            $r -replace '(Loading personal and system profiles took \d+ms\.)',
                        "`e[38;2;68;68;68m`$1`e[0m"
        }
    }
}

# Catppuccin Mocha syntax colors — overrides CTT defaults
Set-PSReadLineOption -Colors @{
    Command   = '#00E5FF'
    Parameter = '#AA00FF'
    Operator  = '#EE00FF'
    Variable  = '#E0E0FF'
    String    = '#00E5AA'
    Number    = '#FFAA00'
    Type      = '#AA00FF'
    Comment   = '#2D2D4A'
    Keyword   = '#EE00FF'
    Error     = '#FF4488'
}

# Better completion — HistoryAndPlugin requires PSReadLine 2.2+
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue

# Carapace — annotated completions (flags, subcommands, argument values) for 1000+ CLI tools
$env:CARAPACE_BRIDGES = 'zsh,fish,bash'
carapace _carapace | Out-String | Invoke-Expression

# Multi-line input — Shift+Enter inserts newline, Enter submits
Set-PSReadLineKeyHandler -Key Shift+Enter -Function AddLine

# ── Font bootstrap (runs once per machine, then skips fast) ──────────────────
$_fontFile = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\JetBrainsMonoNerdFont-Regular.ttf"
$_fontsDir = Join-Path (Split-Path $PROFILE) "fonts"
if (-not (Test-Path $_fontFile) -and (Test-Path $_fontsDir)) {
    New-Item -ItemType Directory -Force "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" | Out-Null
    $reg = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    Get-ChildItem $_fontsDir -Filter "*.ttf" | ForEach-Object {
        $dest = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\$($_.Name)"
        Copy-Item $_.FullName $dest -Force
        Set-ItemProperty $reg "$($_.BaseName) (TrueType)" $dest -ErrorAction SilentlyContinue
    }
    Write-Host "JetBrainsMono NF installed — restart Windows Terminal to apply." -ForegroundColor Cyan
}

# ── Windows Terminal font (idempotent, safe on any machine) ──────────────────
$_wt = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if ((Test-Path $_wt) -and (Get-Content $_wt -Raw) -notmatch 'JetBrainsMono NF') {
    try {
        $s = Get-Content $_wt -Raw | ConvertFrom-Json
        if (-not ($s.profiles.defaults | Get-Member font -ErrorAction SilentlyContinue)) {
            $s.profiles.defaults | Add-Member -MemberType NoteProperty -Name font `
                -Value ([PSCustomObject]@{ face = 'JetBrainsMono NF'; size = 11 }) -Force
        } else {
            $s.profiles.defaults.font.face = 'JetBrainsMono NF'
        }
        $s | ConvertTo-Json -Depth 20 | Set-Content $_wt -Encoding UTF8
    } catch {}
}

# Fastfetch on interactive sessions only
if ($Host.Name -eq 'ConsoleHost' -and [Environment]::UserInteractive) {
    $ffConfig = Join-Path (Split-Path $PROFILE) "fastfetch\config.jsonc"
    $ffExe = (Get-Command fastfetch -ErrorAction SilentlyContinue)?.Source
    if (-not $ffExe) {
        $ffExe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Fastfetch*" `
            -Recurse -Filter "fastfetch.exe" -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if ($ffExe) {
        Push-Location (Split-Path $ffConfig)
        try { & $ffExe --config $ffConfig } finally { Pop-Location }
    }
}
