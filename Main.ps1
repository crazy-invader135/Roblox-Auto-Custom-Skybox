# --- Version & Update Config ---
$LocalVersion = "1.0.0"
$RepoBase = "https://raw.githubusercontent.com/crazy-invader135/Roblox-Auto-Custom-Skybox/main"
$RemoteVersionURL = "$RepoBase/version.txt"
$RemoteScriptURL  = "$RepoBase/Main.ps1"

# --- 1. Check for Updates ---
try {
    $OnlineVersion = (Invoke-WebRequest -Uri $RemoteVersionURL -UseBasicParsing -TimeoutSec 5).Content.Trim()
    if ($OnlineVersion -gt $LocalVersion) {
        $CurrentScript = $MyInvocation.MyCommand.Path
        Invoke-WebRequest -Uri $RemoteScriptURL -OutFile $CurrentScript
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$CurrentScript"""
        exit
    }
} catch { }

# --- 2. Hide Console & Setup ---
$memberDefinition = @'[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'@
$type = Add-Type -MemberDefinition $memberDefinition -Name "Win32ShowWindow" -Namespace "Win32" -PassThru
$hwnd = (Get-Process -Id $PID).MainWindowHandle
if ($hwnd -ne [IntPtr]::Zero) { [void]$type::ShowWindow($hwnd, 0) }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- 3. Persistent Path Logic (Fixes the "Path is null" error) ---
$AppName = "RobloxSkyManager"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
if (-not (Test-Path $InstallDir)) { New-Item -Path $InstallDir -ItemType Directory }

$configPath = Join-Path $InstallDir "config.json"
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\RobloxSkyAuto.lnk"
$timer = New-Object System.Windows.Forms.Timer

# --- 4. GUI Setup ---
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

# --- 5. Functions ---
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
    $found = Get-ChildItem -Path $basePath -Recurse -Filter "sky512_up.tex" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        Get-ChildItem -Path $pathDisplay.Text -Filter "sky512_*.tex" | ForEach-Object { Copy-Item $_.FullName -Destination $found.DirectoryName -Force }
        $statusLabel.Text = "Last Sync: $(Get-Date -Format 'HH:mm:ss')`nApplied to: $($found.DirectoryName)"
    }
}

# --- 6. Listeners ---
$btnBrowse.Add_Click({ $browser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($browser.ShowDialog() -eq "OK") { $pathDisplay.Text = $browser.SelectedPath; Save-Config } })
$btnPreview.Add_Click({ if (Test-Path $pathDisplay.Text) { $img = Join-Path $pathDisplay.Text "! SCREENSHOT.png"; if (Test-Path $img) { Start-Process $img } } })
$btnRun.Add_Click({ Sync-Textures })
$btnTray.Add_Click({ $form.Hide() })
$menuSync.Add_Click({ Sync-Textures })
$notifyIcon.Add_DoubleClick({ $form.Show(); $form.WindowState = "Normal" })
$menuOpen.Add_Click({ $form.Show(); $form.WindowState = "Normal" })
$menuExit.Add_Click({ $notifyIcon.Dispose(); $form.Close(); [Environment]::Exit(0) })
$timer.Interval = 600000; $timer.Add_Tick({ if ($chkSync.Checked) { Sync-Textures } })
$chkBoot.Add_CheckedChanged({
    if ($chkBoot.Checked) {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($startupPath)
        $Shortcut.TargetPath = "powershell.exe"; $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$($MyInvocation.MyCommand.Path)"" -Background"; $Shortcut.Save()
    } else { if (Test-Path $startupPath) { Remove-Item $startupPath } }
    Save-Config
})

# --- 7. Execution ---
Load-Config
$args -contains "-Background" ? $form.Hide() : $form.Show()
[System.Windows.Forms.Application]::Run($form)
