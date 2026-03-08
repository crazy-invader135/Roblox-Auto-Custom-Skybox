# --- 1. Version & Update Config ---
$LocalVersion = "1.0.1"
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

# --- 4. Safe Console Hiding (Compatible with PS 5.1) ---
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
$notifyIcon.Text = "Roblox Sky Sync"; $notifyIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuOpen = $contextMenu.Items.Add("Open GUI"); $menuSync = $contextMenu.Items.Add("Sync Now"); $menuExit = $contextMenu.Items.Add("Exit")
$notifyIcon.ContextMenuStrip = $contextMenu

$label = New-Object System.Windows.Forms.Label; $label.Text = "Select custom texture folder:"; $label.Location = "20, 20"; $label.Size = "350, 20"; $form.Controls.Add($label)
$pathDisplay = New-Object System.Windows.Forms.TextBox; $pathDisplay.Location = "20, 45"; $pathDisplay.Size = "280, 20"; $pathDisplay.ReadOnly = $true; $form.Controls.Add($pathDisplay)
$btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Text = "Browse..."; $btnBrowse.Location = "310, 43"; $form.Controls.Add($btnBrowse)
$btnPreview = New-Object System.Windows.Forms.Button; $btnPreview.Text = "Preview Sky (! SCREENSHOT.png)"; $btnPreview.Location = "20, 75"; $btnPreview.Size = "365, 30"; $form.Controls.Add($btnPreview)
$chkSync = New-Object System.Windows.Forms.CheckBox; $chkSync.Text = "Enable Auto-Sync (10 Mins)"; $chkSync.Location = "25, 115"; $form.Controls.Add($chkSync)
$chkBoot = New-Object System.Windows.Forms.CheckBox; $chkBoot.Text = "Run on Windows Startup"; $chkBoot.Location = "25, 140"; $form.Controls.Add($chkBoot)
$btnRun = New-Object System.Windows.Forms.Button; $btnRun.Text = "Apply Once Now"; $btnRun.Location = "20, 180"; $btnRun.Size = "365, 40"; $btnRun.BackColor = "LightGreen"; $form.Controls.Add($btnRun)
$btnTray = New-Object System.Windows.Forms.Button; $btnTray.Text = "Minimize to System Tray"; $btnTray.Location = "20, 230"; $btnTray.Size = "365, 30"; $form.Controls.Add($btnTray)
$statusLabel = New-Object System.Windows.Forms.Label; $statusLabel.Text = "Ready."; $statusLabel.Location = "20, 280"; $statusLabel.Size = "365, 100"; $form.Controls.Add($statusLabel)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 600000

# --- 6. Logic Functions ---
function Save-Config {
    $config = @{ SourcePath = $pathDisplay.Text; AutoSync = $chkSync.Checked; RunOnBoot = $chkBoot.Checked }
    $config | ConvertTo-Json | Out-File $configPath
}

function Load-Config {
    if (Test-Path $configPath) {
        $config = Get-Content $configPath | ConvertFrom-Json
        $pathDisplay.Text = $config.SourcePath; $chkSync.Checked = $config.AutoSync; $chkBoot.Checked = $config.RunOnBoot
        if ($chkSync.Checked) { $timer.Start() }
    }
}

function Sync-Textures {
    if (-not $pathDisplay.Text -or -not (Test-Path $pathDisplay.Text)) { return }
    if (Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue) {
        $statusLabel.Text = "Waiting: Roblox is currently open."
        return 
    }

    $basePath = "$env:LOCALAPPDATA\Roblox\Versions"
    $latestVersion = Get-ChildItem -Path $basePath -Directory | 
                     Sort-Object LastWriteTime -Descending | 
                     Where-Object { Test-Path (Join-Path $_.FullName "PlatformContent\pc\textures") } | 
                     Select-Object -First 1

    if ($latestVersion) {
        $destinationPath = Join-Path $latestVersion.FullName "PlatformContent\pc\textures"
        Get-ChildItem -Path $pathDisplay.Text -Filter "sky512_*.tex" | ForEach-Object { 
            Copy-Item $_.FullName -Destination $destinationPath -Force 
        }
        $statusLabel.Text = "Last Sync: $(Get-Date -Format 'HH:mm:ss')`nApplied to: $($latestVersion.Name)"
    } else {
        $statusLabel.Text = "Error: Could not find Roblox texture folder."
    }
}

# --- 7. Event Listeners ---
$btnBrowse.Add_Click({ $browser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($browser.ShowDialog() -eq "OK") { $pathDisplay.Text = $browser.SelectedPath; Save-Config } })
$btnPreview.Add_Click({ if (Test-Path $pathDisplay.Text) { $img = Join-Path $pathDisplay.Text "! SCREENSHOT.png"; if (Test-Path $img) { Start-Process $img } } })
$btnRun.Add_Click({ Sync-Textures })
$btnTray.Add_Click({ $form.Hide() })
$menuSync.Add_Click({ Sync-Textures })
$notifyIcon.Add_DoubleClick({ $form.Show(); $form.WindowState = "Normal"; $form.Activate() })
$menuOpen.Add_Click({ $form.Show(); $form.WindowState = "Normal"; $form.Activate() })
$menuExit.Add_Click({ $notifyIcon.Dispose(); $form.Close(); [Environment]::Exit(0) })
$timer.Add_Tick({ if ($chkSync.Checked) { Sync-Textures } })
$chkBoot.Add_CheckedChanged({
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\RobloxSkyAuto.lnk"
    if ($chkBoot.Checked) {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($startupPath)
        $Shortcut.TargetPath = "powershell.exe"; $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$(Join-Path $InstallDir 'Main.ps1')"" -Background"; $Shortcut.Save()
    } else { if (Test-Path $startupPath) { Remove-Item $startupPath } }
    Save-Config
})

# --- 8. Execution ---
Load-Config
if ($args -contains "-Background") { $form.Hide() } else { $form.Show() }
[System.Windows.Forms.Application]::Run($form)
