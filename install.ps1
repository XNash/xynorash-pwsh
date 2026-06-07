#Requires -Version 7
<#
.SYNOPSIS
    Bootstrap the XYNORASH PowerShell environment on any Windows machine.
.DESCRIPTION
    Installs all required tools (oh-my-posh, fastfetch, carapace, zoxide),
    PowerShell modules (Terminal-Icons, PSReadLine), JetBrainsMono NF fonts,
    and copies all config files to the correct locations.
    Run once per machine. Safe to re-run — all steps are idempotent.
.EXAMPLE
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    .\install.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo       = $PSScriptRoot
$profileDir = Split-Path $PROFILE

function Write-Step($msg) { Write-Host "  -> $msg" -ForegroundColor Cyan    }
function Write-Ok($msg)   { Write-Host "  v  $msg" -ForegroundColor Green   }
function Write-Warn($msg) { Write-Host "  !  $msg" -ForegroundColor Yellow  }

Write-Host ""
Write-Host "  XYNORASH PowerShell Setup" -ForegroundColor Magenta
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkMagenta
Write-Host ""

# ── 1. winget packages ────────────────────────────────────────────────────────

$packages = @(
    @{ Id = 'JanDeDobbeleer.OhMyPosh'; Name = 'oh-my-posh' },
    @{ Id = 'Fastfetch-cli.Fastfetch'; Name = 'fastfetch'  },
    @{ Id = 'rsteube.Carapace';        Name = 'carapace'   },
    @{ Id = 'ajeetdsouza.zoxide';      Name = 'zoxide'     }
)

Write-Host "  [1/5] Tools" -ForegroundColor DarkCyan
foreach ($pkg in $packages) {
    $found = winget list --id $pkg.Id --exact 2>$null | Select-String $pkg.Id
    if ($found) {
        Write-Ok "$($pkg.Name) already installed"
    } else {
        Write-Step "Installing $($pkg.Name)..."
        winget install $pkg.Id --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
        Write-Ok "$($pkg.Name) installed"
    }
}

# ── 2. PowerShell modules ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "  [2/5] PowerShell modules" -ForegroundColor DarkCyan
$modules = @('Terminal-Icons', 'PSReadLine')
foreach ($mod in $modules) {
    if (Get-Module -ListAvailable -Name $mod -ErrorAction SilentlyContinue) {
        Write-Ok "$mod already available"
    } else {
        Write-Step "Installing module $mod..."
        Install-Module $mod -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction Stop
        Write-Ok "$mod installed"
    }
}

# ── 3. Fonts ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  [3/5] Fonts" -ForegroundColor DarkCyan
$fontsDest = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$reg = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
New-Item -ItemType Directory -Force $fontsDest | Out-Null

foreach ($ttf in Get-ChildItem (Join-Path $repo 'fonts') -Filter '*.ttf') {
    $dest = Join-Path $fontsDest $ttf.Name
    if (Test-Path $dest) {
        Write-Ok "Font $($ttf.BaseName) already registered"
    } else {
        Copy-Item $ttf.FullName $dest -Force
        Set-ItemProperty $reg "$($ttf.BaseName) (TrueType)" $dest -ErrorAction SilentlyContinue
        Write-Ok "Font $($ttf.BaseName) installed"
    }
}

# ── 4. Config files ───────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  [4/5] Config files  ->  $profileDir" -ForegroundColor DarkCyan
New-Item -ItemType Directory -Force $profileDir | Out-Null

foreach ($f in @('profile.ps1', 'Microsoft.PowerShell_profile.ps1', 'xynorash.omp.json')) {
    Copy-Item (Join-Path $repo $f) (Join-Path $profileDir $f) -Force
    Write-Ok $f
}

$ffDest = Join-Path $profileDir 'fastfetch'
New-Item -ItemType Directory -Force $ffDest | Out-Null
Copy-Item (Join-Path $repo 'fastfetch\*') $ffDest -Recurse -Force
Write-Ok 'fastfetch/'

$fontsDirDest = Join-Path $profileDir 'fonts'
New-Item -ItemType Directory -Force $fontsDirDest | Out-Null
Copy-Item (Join-Path $repo 'fonts\*') $fontsDirDest -Force
Write-Ok 'fonts/'

# ── 5. Windows Terminal ───────────────────────────────────────────────────────

Write-Host ""
Write-Host "  [5/5] Windows Terminal" -ForegroundColor DarkCyan
$wt = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wt) {
    try {
        $s = Get-Content $wt -Raw | ConvertFrom-Json
        $alreadySet = ($s.profiles.defaults.PSObject.Properties.Name -contains 'font') -and
                      ($s.profiles.defaults.font.face -eq 'JetBrainsMono NF')
        if (-not $alreadySet) {
            if (-not ($s.profiles.defaults | Get-Member font -ErrorAction SilentlyContinue)) {
                $s.profiles.defaults | Add-Member -MemberType NoteProperty -Name font `
                    -Value ([PSCustomObject]@{ face = 'JetBrainsMono NF'; size = 11 }) -Force
            } else {
                $s.profiles.defaults.font.face = 'JetBrainsMono NF'
            }
            if (-not ($s.PSObject.Properties.Name -contains 'scrollToBottomOnInput')) {
                $s | Add-Member -MemberType NoteProperty -Name scrollToBottomOnInput -Value $true -Force
            }
            $s | ConvertTo-Json -Depth 20 | Set-Content $wt -Encoding UTF8
            Write-Ok "Font set to JetBrainsMono NF, scrollToBottomOnInput enabled"
        } else {
            Write-Ok "Windows Terminal already configured"
        }
    } catch {
        Write-Warn "Could not update Windows Terminal settings: $_"
    }
} else {
    Write-Warn "Windows Terminal not found — install it from the Microsoft Store, then re-run"
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkMagenta
Write-Host "  Setup complete. Open a new PowerShell tab." -ForegroundColor Green
Write-Host ""
