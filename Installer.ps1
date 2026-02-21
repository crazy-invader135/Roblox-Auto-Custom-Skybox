# --- Configuration ---
$AppName = "RobloxSkyManager"
$GithubURL = "https://raw.githubusercontent.com/crazy-invader135/Roblox-Auto-Custom-Skybox/refs/heads/main/Main.ps1"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$ExePath = Join-Path $InstallDir "$AppName.ps1" # We will install the script first
$ShortcutPath = "$env:USERPROFILE\Desktop\$AppName.lnk"
$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\$AppName.lnk"

Write-Host "Starting Installation of $AppName..." -ForegroundColor Cyan

# 1. Create Installation Directory
if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
    Write-Host "[1/4] Created folder at $InstallDir" -ForegroundColor Green
}

# 2. Download the latest code from GitHub
try {
    Invoke-WebRequest -Uri $GithubURL -OutFile $ExePath
    Write-Host "[2/4] Successfully downloaded latest script from GitHub." -ForegroundColor Green
} catch {
    Write-Error "Failed to download script. Check your internet connection or URL."
    return
}

# 3. Create initial config.json if it doesn't exist
$configPath = Join-Path $InstallDir "config.json"
if (-not (Test-Path $configPath)) {
    $defaultConfig = @{ SourcePath = ""; AutoSync = $false; RunOnBoot = $false }
    $defaultConfig | ConvertTo-Json | Out-File $configPath
    Write-Host "[3/4] Initialized configuration file." -ForegroundColor Green
}

# 4. Create Shortcuts (Desktop and Start Menu)
$WshShell = New-Object -ComObject WScript.Shell
foreach ($path in @($ShortcutPath, $StartMenuPath)) {
    $Shortcut = $WshShell.CreateShortcut($path)
    $Shortcut.TargetPath = "powershell.exe"
    # Runs the script hidden
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$ExePath"""
    $Shortcut.Description = "Roblox Custom Skybox Manager"
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.Save()
}
Write-Host "[4/4] Shortcuts created on Desktop and Start Menu." -ForegroundColor Green

Write-Host "`nInstallation Complete! You can now launch $AppName from your Desktop." -ForegroundColor Yellow
Pause
