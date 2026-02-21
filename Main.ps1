# --- Version Configuration ---
$LocalVersion = "1.0.0"
$RemoteVersionURL = "https://raw.githubusercontent.com/crazy-invader135/Roblox-Auto-Custom-Skybox/main/version.txt"
$RemoteScriptURL  = "https://raw.githubusercontent.com/crazy-invader135/Roblox-Auto-Custom-Skybox/main/Main.ps1"

# --- 1. Check for Updates ---
try {
    $OnlineVersion = (Invoke-WebRequest -Uri $RemoteVersionURL -UseBasicParsing).Content.Trim()
    if ($OnlineVersion -gt $LocalVersion) {
        $CurrentScript = $MyInvocation.MyCommand.Path
        Invoke-WebRequest -Uri $RemoteScriptURL -OutFile $CurrentScript
        # Restart the script to run the new version
        Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -File ""$CurrentScript"""
        exit
    }
} catch {
    # If GitHub is down or no internet, just continue to run the app
}

# --- 2. Existing App Logic Starts Here ---
# (Include the ShowWindow, GUI setup, and Sync-Textures code we built previously)
# ... [Rest of your Main.ps1 code] ...
