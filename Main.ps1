# --- 1. Path & Identity Setup ---
$AppName = "RobloxSkyManager"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
if (-not (Test-Path $InstallDir)) { New-Item -Path $InstallDir -ItemType Directory -Force }
$configPath = Join-Path $InstallDir "config.json"

# --- 2. Safe Console Hiding (Fixed Here-String) ---
try {
    $memberDefinition = @"
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@
    $type = Add-Type -MemberDefinition $memberDefinition -Name "Win32ShowWindow" -Namespace "Win32" -PassThru -ErrorAction SilentlyContinue
    $hwnd = (Get-Process -Id $PID).MainWindowHandle
    if ($hwnd -ne [IntPtr]::Zero) { [void]$type::ShowWindow($hwnd, 0) }
} catch { }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- 3. Update Logic ---
$LocalVersion = "1.0.0"
$RepoBase = "https://raw.githubusercontent.com/crazy-invader135/Roblox-Auto-Custom-Skybox/main"

try {
    $OnlineVersion = (Invoke-WebRequest -Uri "$RepoBase/version.txt" -UseBasicParsing -TimeoutSec 2).Content.Trim()
    if ($OnlineVersion -gt $LocalVersion) {
        Invoke-WebRequest -Uri "$RepoBase/Main.ps1" -OutFile $MyInvocation.MyCommand.Path
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$($MyInvocation.MyCommand.Path)"""
        exit
    }
} catch { }

# ... [Insert your GUI code here] ...

# --- 4. Fixed Startup Logic (No more "?" symbol) ---
Load-Config
if ($args -contains "-Background") {
    $form.Hide()
} else {
    $form.Show()
}
[System.Windows.Forms.Application]::Run($form)
