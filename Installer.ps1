# --- Configuration ---
$AppName = "RobloxSkyManager"
$RepoBase = "https://raw.githubusercontent.com/crazy-invader135/Roblox-Auto-Custom-Skybox/main"
$ScriptURL = "$RepoBase/Main.ps1"
$IconURL   = "$RepoBase/RBLX_SKIES.ico"

$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$ScriptPath = Join-Path $InstallDir "Main.ps1"
$IconPath   = Join-Path $InstallDir "RBLX_SKIES.ico"
$ShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\$AppName.lnk"

Write-Host "Installing $AppName..." -ForegroundColor Cyan

# 1. Create Folder
if (-not (Test-Path $InstallDir)) { New-Item -Path $InstallDir -ItemType Directory | Out-Null }

# 2. Download Files
Write-Host "Downloading components..." -ForegroundColor Gray
Invoke-WebRequest -Uri $ScriptURL -OutFile $ScriptPath
Invoke-WebRequest -Uri $IconURL   -OutFile $IconPath

# 3. Create Shortcut with Icon
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$ScriptPath"""
$Shortcut.IconLocation = $IconPath # This makes it look like a real app!
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Description = "Roblox Custom Skybox Manager"
$Shortcut.Save()

Write-Host "`nInstallation Successful!" -ForegroundColor Green
Write-Host "You can now find '$AppName' in your Start Menu." -ForegroundColor White
Pause
