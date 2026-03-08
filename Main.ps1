# --- 1. Version & Update Config ---
$LocalVersion = "1.0.3"
$RepoBase = "https://raw.githubusercontent.com/crazy-invader135/Roblox-Auto-Custom-Skybox/main"
$RemoteVersionURL = "$RepoBase/version.txt"
$RemoteScriptURL  = "$RepoBase/Main.ps1"

# --- 2. Silent Update Check ---
try {
    $OnlineVersion = (Invoke-WebRequest -Uri $RemoteVersionURL -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop).Content.Trim()
    if ($OnlineVersion -gt $LocalVersion) {
        $CurrentScript = $MyInvocation.MyCommand.Path
        if ($CurrentScript) {
            Invoke-WebRequest -Uri $RemoteScriptURL -OutFile $CurrentScript -ErrorAction Stop
            Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$CurrentScript"""
            exit
        }
    }
} catch { }

# --- 3. Path & Identity Setup ---
$AppName = "RobloxSkyManager"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
if (-not (Test-Path $InstallDir)) { New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null }
$configPath = Join-Path $InstallDir "config.json"

# --- 4. Safe Console Hiding ---
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

# --- 5. GUI Setup ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Roblox Sky Manager"; $form.Size = "420, 520"; $form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "FixedDialog"

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Visible = $true

# UI Elements (Labels, Textbox, Buttons)
$label = New-Object System.Windows.Forms.Label; $label.Text = "Select custom texture folder:"; $label.Location = "20, 20"; $label.Size = "350, 20"; $form.Controls.Add($label)
$pathDisplay = New-Object System.Windows.Forms.TextBox; $pathDisplay.Location = "20, 45"; $pathDisplay.Size = "280, 20"; $pathDisplay.ReadOnly = $true; $form.Controls.Add($pathDisplay)
$btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Text = "Browse..."; $btnBrowse.Location = "310, 43"; $form.Controls.Add($btnBrowse)
$btnRun = New-Object System.Windows.Forms.Button; $btnRun.Text = "Apply Once Now"; $btnRun.Location = "20, 180"; $btnRun.Size = "365, 40"; $btnRun.BackColor = "LightGreen"; $form.Controls.Add($btnRun)
$statusLabel = New-Object System.Windows.Forms.Label; $statusLabel.Text = "Ready."; $statusLabel.Location = "20, 280"; $statusLabel.Size = "365, 100"; $form.Controls.Add($statusLabel)
$versionLabel = New-Object System.Windows.Forms.Label; $versionLabel.Text = "v$LocalVersion"; $versionLabel.Location = "340, 455"; $versionLabel.ForeColor = "Gray"; $form.Controls.Add($versionLabel)

# --- 6. Sync Logic (The Fix) ---
function Sync-Textures {
    if (-not $pathDisplay.Text -or -not (Test-Path $pathDisplay.Text)) { return }
    
    # KILL ROBLOX FIRST (Essential for overwriting files)
    Stop-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue

    $basePath = "$env:LOCALAPPDATA\Roblox\Versions"
    $versionFolders = Get-ChildItem -Path $basePath -Directory
    $log = ""

    # Supported names: sky512_up, sky512_dn, sky512_lf, sky512_rt, sky512_ft, sky512_bk
    $customFiles = Get-ChildItem -Path $pathDisplay.Text | Where-Object { $_.BaseName -like "sky512_*" }

    foreach ($folder in $versionFolders) {
        $texPath = Join-Path $folder.FullName "PlatformContent\pc\textures"
        if (Test-Path $texPath) {
            foreach ($file in $customFiles) {
                $destFile = Join-Path $texPath ($file.BaseName + ".tex")
                try {
                    # REMOVE EXISTING FILE FIRST
                    if (Test-Path $destFile) { Remove-Item $destFile -Force -ErrorAction Stop }
                    # COPY NEW FILE
                    Copy-Item -Path $file.FullName -Destination $destFile -Force -ErrorAction Stop
                } catch { }
            }
            $log += "Updated: $($folder.Name)`n"
        }
    }
    $statusLabel.Text = if ($log) { "SUCCESS:`n$log" } else { "Error: No Roblox folders found." }
}

# --- 7. Listeners ---
$btnBrowse.Add_Click({ $browser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($browser.ShowDialog() -eq "OK") { $pathDisplay.Text = $browser.SelectedPath; $config = @{SourcePath=$pathDisplay.Text}; $config | ConvertTo-Json | Out-File $configPath } })
$btnRun.Add_Click({ Sync-Textures })

# --- 8. Execution ---
if (Test-Path $configPath) { $pathDisplay.Text = (Get-Content $configPath | ConvertFrom-Json).SourcePath }
$form.ShowDialog()
