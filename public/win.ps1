# Check if the script is running with Administrator privileges
$IsAdmin = [System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()
$script:restorePointCreated = $false

function createRestorePointIfNeeded {
    if (-not $script:restorePointCreated) {
        Write-Host "Creating a system restore point..."
        try {
            Checkpoint-Computer -Description "Winzilla Restore Point" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            $script:restorePointCreated = $true
            Write-Host "System restore point created successfully."
        }
        catch {
            Write-Host "Failed to create system restore point: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

if (-not $IsAdmin.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges."
    $argList = @()
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $argList += if ($_.Value -is [switch] -and $_.Value) {
            "-$($_.Key)"
        }
        elseif ($_.Value) {
            "-$($_.Key) `"$($_.Value)`""
        }
    }

    $script = if ($MyInvocation.MyCommand.Path) {
        "& { & '$($MyInvocation.MyCommand.Path)' $argList }"
    }
    else {
        "iex '$($MyInvocation.MyCommand.Path)' $argList"
    }

    $powershellcmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    Start-Process $powershellcmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command $script" -Verb RunAs
    Exit
}
else {
    Write-Host "Administrator privileges detected. Proceeding with the script."
}

# Load Assemblies for Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Define the color palette ---
$colorPalette = @{
    Background      = [System.Drawing.Color]::FromArgb(20, 30, 25); # A deep, dark green
    Foreground      = [System.Drawing.Color]::FromArgb(35, 55, 45); # A slightly lighter green for button backs
    PrimaryText     = [System.Drawing.Color]::FromArgb(200, 255, 215); # A soft, light green for text
    Highlight       = [System.Drawing.Color]::FromArgb(80, 150, 100); # A brighter green for borders/highlights
    WhiteText       = [System.Drawing.Color]::White;
    TabHeader       = [System.Drawing.Color]::FromArgb(45, 75, 60); # Color for tab headers
}

# Create the main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Winzilla GUI"
$mainForm.Size = New-Object System.Drawing.Size(1024, 1040) # FIX: Increased height to fit all controls
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$mainForm.MaximizeBox = $false
$mainForm.MinimizeBox = $true
$mainForm.BackColor = $colorPalette.Background

# Create a rich text box for ASCII art
$asciiTextBox = New-Object System.Windows.Forms.RichTextBox
$asciiTextBox.Location = New-Object System.Drawing.Point(20, 20)
$asciiTextBox.Size = New-Object System.Drawing.Size(976, 150)
$asciiTextBox.Multiline = $true
$asciiTextBox.ReadOnly = $true
$asciiTextBox.BackColor = $colorPalette.Background
$asciiTextBox.ForeColor = $colorPalette.Highlight
$asciiTextBox.Font = New-Object System.Drawing.Font("Consolas", 12)
$asciiTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$asciiTextBox.SelectionAlignment = [System.Windows.Forms.HorizontalAlignment]::Center
$asciiTextBox.WordWrap = $false

$asciiArtRaw = @"
     __     __     __     __   __     ______     __     __         __         ______    
    /\ \  _ \ \   /\ \   /\ "-.\ \   /\___  \   /\ \   /\ \       /\ \       /\  __ \   
    \ \ \/ ".\ \  \ \ \  \ \ \--\ \  \/_/  /__  \ \ \  \ \ \____  \ \ \____  \ \  __ \  
     \ \__/".~\_\  \ \_\  \ \_\\'\_\   /\_____\  \ \_\  \ \_____\  \ \_____\  \ \_\ \_\ 
      \/_/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/   \/_____/   \/_____/   \/_/\/_/ 
"@
$asciiArtFixed = ($asciiArtRaw -split "`n") -join "`n"
$asciiTextBox.Text = $asciiArtFixed
$mainForm.Controls.Add($asciiTextBox)

# FIX: Create a Panel to act as a colored border for the TabControl
$tabControlContainer = New-Object System.Windows.Forms.Panel
$tabControlContainer.Location = New-Object System.Drawing.Point(20, 180)
$tabControlContainer.Size = New-Object System.Drawing.Size(976, 600)
$tabControlContainer.BackColor = $colorPalette.Highlight # This is the border color
$mainForm.Controls.Add($tabControlContainer)


# --- Create TabControl ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(2, 2) # Placed inside the container
$tabControl.Size = New-Object System.Drawing.Size(972, 596) # Slightly smaller than container
$tabControl.BackColor = $colorPalette.Background
$tabControl.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
$tabControl.ItemSize = New-Object System.Drawing.Size(150, 30)
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$tabControl.Add_DrawItem({
    param($sender, $e)
    $g = $e.Graphics
    $tabRect = $e.Bounds
    $tabText = $sender.TabPages[$e.Index].Text

    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center

    $tabBackColor = if ($sender.SelectedIndex -eq $e.Index) {
        $colorPalette.Highlight
    } else {
        $colorPalette.TabHeader
    }

    $brush = New-Object System.Drawing.SolidBrush($tabBackColor)
    $g.FillRectangle($brush, $tabRect)

    $font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $textBrush = New-Object System.Drawing.SolidBrush($colorPalette.PrimaryText)
    $g.DrawString($tabText, $font, $textBrush, [System.Drawing.RectangleF]$tabRect, $stringFormat)

    # No need to draw a border here, the background color difference implies selection
})
$tabControlContainer.Controls.Add($tabControl) # Add to the container panel

# Create TabPages
$homeTabPage = New-Object System.Windows.Forms.TabPage "Home"
$homeTabPage.Name = "TabPageHome"
$homeTabPage.BackColor = $colorPalette.Background
$tabControl.Controls.Add($homeTabPage)

$wingetTabPage = New-Object System.Windows.Forms.TabPage "Winget App Install"
$wingetTabPage.Name = "TabPageWinget"
$wingetTabPage.BackColor = $colorPalette.Background
$tabControl.Controls.Add($wingetTabPage)

$advancedTabPage = New-Object System.Windows.Forms.TabPage "Advanced Options"
$advancedTabPage.Name = "TabPageAdvanced"
$advancedTabPage.BackColor = $colorPalette.Background
$tabControl.Controls.Add($advancedTabPage)

# Create a rich text box for output (now BELOW the TabControl, global)
$outputTextBox = New-Object System.Windows.Forms.RichTextBox
$outputTextBox.Location = New-Object System.Drawing.Point(20, ([int]$tabControlContainer.Location.Y + [int]$tabControlContainer.Size.Height + 10))
$outputTextBox.Size = New-Object System.Drawing.Size(976, 150) # FIX: Adjusted height
$outputTextBox.Multiline = $true
$outputTextBox.ReadOnly = $true
$outputTextBox.ScrollBars = "Vertical"
$outputTextBox.BackColor = $colorPalette.Background
$outputTextBox.ForeColor = $colorPalette.PrimaryText
$outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle # Give it a subtle border
$mainForm.Controls.Add($outputTextBox)

# Function to write messages to the GUI output box
function Write-GUIOutput {
    param($Message)
    if ($outputTextBox) {
        $outputTextBox.AppendText("$($Message)`r`n")
        $outputTextBox.ScrollToCaret()
    } else {
        Write-Host "GUI Output box not initialized. Message: $Message"
    }
}

# --- Common Functions ---

function invokeCTT {
    createRestorePointIfNeeded
    Write-Host "Executing invokeCTT function..."
    Write-GUIOutput "Executing invokeCTT function... (Check console for details)"
    Invoke-RestMethod https://christitus.com/win | Invoke-Expression
    Write-Host "invokeCTT function completed."
    Write-GUIOutput "invokeCTT function completed."
}

function disableUpdates {
    createRestorePointIfNeeded
    Write-Host "Executing disableUpdates function..."
    Write-GUIOutput "Executing disableUpdates function... (Check console for details)"
    Write-Host "Disabling driver offering through Windows Update..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -Type DWord -Value 0
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1
    Write-Host "Disabling Windows Update automatic restart..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
    Write-Host "Disabled driver offering through Windows Update"
    If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel" -Type DWord -Value 20
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 4

    Write-Host "================================="
    Write-Host "--- Updates Set to Recommended ---"
    Write-Host "================================="
    Write-GUIOutput "disableUpdates function completed."
    Write-GUIOutput "disableUpdates function completed."
}

function ultimatePowerPlan {
    createRestorePointIfNeeded
    Write-Host "Executing ultimatePowerPlan function..."
    Write-GUIOutput "Executing ultimatePowerPlan function... (Check console for details)"
    Write-Host "Checking if Ultimate Performance plan is available..."

    $powerPlans = powercfg /list

    if ($powerPlans -notmatch "Ultimate Performance") {
        $currentPlan = powercfg /getactivescheme

        if ($currentPlan -notmatch "06306d31-12c8-4900-86c3-92406571b6fe") {
            Write-Host "Enabling Ultimate Performance plan..."
            powercfg -setactive 06306d31-12c8-4900-86c3-92406571b6fe
            Write-Host "================================="
            Write-Host "--- Set Ultimate Power Plan ---"
            Write-Host "================================="
        }
        else {
            Write-Host "Ultimate Performance plan is already active."
        }
    }
    else {
        Write-Host "Ultimate Performance plan is not available on this system."
    }
    Write-Host "ultimatePowerPlan function completed."
    Write-GUIOutput "ultimatePowerPlan function completed."
}

function defenderTweaks {
    createRestorePointIfNeeded
    Write-Host "Executing defenderTweaks function..."
    Write-GUIOutput "Executing defenderTweaks function... (Check console for details)"
    Stop-Service -Name "WinDefend" -Force -ErrorAction SilentlyContinue
    Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue

    Set-Service -Name "WinDefend" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "wuauserv" -StartupType Disabled -ErrorAction SilentlyContinue

    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiVirus" -Value 1 -ErrorAction SilentlyContinue
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Provider -eq 'Microsoft.PowerShell.Core\FileSystem' }

    foreach ($drive in $drives) {
        Write-Host "Adding $($drive.Name):\ to Windows Defender exclusions..."
        Set-MpPreference -ExclusionPath "$($drive.Name):\" -ErrorAction SilentlyContinue
    }

    Write-Host "All detected drives have been added to Windows Defender exclusions."
    Write-Host "Windows Defender has been disabled permanently."
    Write-Host "defenderTweaks function completed."
    Write-GUIOutput "defenderTweaks function completed."
}

function removeEdge {
    createRestorePointIfNeeded
    Write-Host "Running Remove Edge batch script..."
    Write-GUIOutput "Running Remove Edge batch script... (Check console for details)"
    $batchScriptUrl = "https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/setup.exe"

    try {
        $webClient = New-Object System.Net.WebClient
        $batchScriptContentBytes = $webClient.DownloadData($batchScriptUrl)
    }
    catch {
        Write-Host "Failed to download Edge removal script: $($_.Exception.Message)" -ForegroundColor Red
        Write-GUIOutput "Failed to download Edge removal script."
        return
    }

    if ($batchScriptContentBytes -and $batchScriptContentBytes.Length -gt 0) {
        $tempDir = [System.IO.Path]::GetTempPath()
        $tempExecutablePath = [System.IO.Path]::Combine($tempDir, "EdgeRemover.exe")

        try {
            [System.IO.File]::WriteAllBytes($tempExecutablePath, $batchScriptContentBytes)
            Write-Host "Executing Edge removal executable..."
            Write-GUIOutput "Executing Edge removal executable. Please follow any prompts."
            Start-Process $tempExecutablePath -Verb RunAs -Wait
            Write-Host "Edge removal executable completed."
            Write-GUIOutput "Edge removal executable completed."
        }
        catch {
            Write-Host "Error executing Edge removal script: $($_.Exception.Message)" -ForegroundColor Red
            Write-GUIOutput "Error executing Edge removal script."
        }
        finally {
            if (Test-Path $tempExecutablePath) {
                Remove-Item $tempExecutablePath -ErrorAction SilentlyContinue
            }
        }
    }
    else {
        Write-Host "Downloaded Edge removal script content is empty." -ForegroundColor Red
        Write-GUIOutput "Downloaded Edge removal script content is empty."
    }
    Write-Host "removeEdge function completed."
    Write-GUIOutput "removeEdge function completed."
}

function invokeRaphire {
    createRestorePointIfNeeded
    Write-Host "Executing invokeRaphire function..."
    Write-GUIOutput "Executing invokeRaphire function... (Check console for details)"
    & ([scriptblock]::Create((Invoke-RestMethod "https://debloat.raphi.re/")))
    Write-Host "invokeRaphire function completed."
    Write-GUIOutput "invokeRaphire function completed."
}

function uninstallUWPApps {
    createRestorePointIfNeeded
    Write-Host "Executing uninstallUWPApps function..."
    Write-GUIOutput "Executing uninstallUWPApps function... (Check console for details)"
    $appsToRemove = @(
        "Microsoft.BingNews", "Microsoft.BingWeather", "Microsoft.GetHelp",
        "Microsoft.Getstarted", "Microsoft.Messaging", "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftStickyNotes", "Microsoft.MixedReality.Portal", "Microsoft.MSPaint",
        "Microsoft.Office.OneNote", "Microsoft.People", "Microsoft.SkypeApp",
        "Microsoft.WindowsAlarms", "Microsoft.WindowsCamera", "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder", "Microsoft.Xbox.TCUI", "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay", "Microsoft.XboxIdentityProvider", "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.ZuneVideo", "Microsoft.ZuneMusic"
    )

    foreach ($app in $appsToRemove) {
        Write-Host "Attempting to remove $app..."
        Get-AppxPackage -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$app removed successfully."
            Write-GUIOutput "$app removed successfully."
        }
        else {
            Write-Host "Could not remove $app (possibly not installed or already removed)." -ForegroundColor Yellow
            Write-GUIOutput "Could not remove $app (possibly not installed or already removed)."
        }
    }
    Write-Host "uninstallUWPApps function completed."
    Write-GUIOutput "uninstallUWPApps function completed."
}

function disableCortana {
    createRestorePointIfNeeded
    Write-Host "Executing disableCortana function..."
    Write-GUIOutput "Executing disableCortana function... (Check console for details)"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "Cortana has been disabled."
    Write-GUIOutput "Cortana has been disabled."
    Write-Host "disableCortana function completed."
    Write-GUIOutput "disableCortana function completed."
}

function disableTelemetry {
    createRestorePointIfNeeded
    Write-Host "Executing disableTelemetry function..."
    Write-GUIOutput "Executing disableTelemetry function... (Check console for details)"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "CommercialDataOptIn" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" -Name "TelemetryConsent" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name "dmwappushservice" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "Telemetry and Data Collection disabled."
    Write-GUIOutput "Telemetry and Data Collection disabled."
    Write-Host "disableTelemetry function completed."
    Write-GUIOutput "disableTelemetry function completed."
}

function removeOneDrive {
    createRestorePointIfNeeded
    Write-Host "Executing removeOneDrive function..."
    Write-GUIOutput "Executing removeOneDrive function... (Check console for details)"
    taskkill /f /im OneDrive.exe /fi "STATUS eq RUNNING" >$null 2>&1

    $oneDriveSetup32 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    $oneDriveSetup64 = "$env:SystemRoot\System32\OneDriveSetup.exe"

    if (Test-Path $oneDriveSetup32) {
        & $oneDriveSetup32 /uninstall
        Write-Host "Attempting to uninstall 32-bit OneDrive..."
    }
    if (Test-Path $oneDriveSetup64) {
        & $oneDriveSetup64 /uninstall
        Write-Host "Attempting to uninstall 64-bit OneDrive..."
    }

    Remove-Item -Path "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

    Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Force -ErrorAction SilentlyContinue
    
    Write-Host "OneDrive integration removed."
    Write-GUIOutput "OneDrive integration removed."
    Write-Host "removeOneDrive function completed."
    Write-GUIOutput "removeOneDrive function completed."
}

function disableTaskbarIcons {
    createRestorePointIfNeeded
    Write-Host "Executing disableTaskbarIcons function..."
    Write-GUIOutput "Executing disableTaskbarIcons function... (Check console for details)"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 2 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_MEETNOW_ENABLED" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Write-Host "Meet Now and News and Interests taskbar icons disabled."
    Write-GUIOutput "Meet Now and News and Interests taskbar icons disabled."
    Write-Host "disableTaskbarIcons function completed."
    Write-GUIOutput "disableTaskbarIcons function completed."
}

function disableAdsTracking {
    createRestorePointIfNeeded
    Write-Host "Executing disableAdsTracking function..."
    Write-GUIOutput "Executing disableAdsTracking function... (Check console for details)"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Write-Host "Targeted Ads and Tracking disabled."
    Write-GUIOutput "Targeted Ads and Tracking disabled."
    Write-Host "disableAdsTracking function completed."
    Write-GUIOutput "disableAdsTracking function completed."
}

function showFileExtensions {
    createRestorePointIfNeeded
    Write-Host "Executing showFileExtensions function..."
    Write-GUIOutput "Executing showFileExtensions function... (Check console for details)"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Write-Host "File extensions will now be shown by default."
    Write-GUIOutput "File extensions will now be shown by default."
    Write-Host "showFileExtensions function completed."
    Write-GUIOutput "showFileExtensions function completed."
}

function disableGameBar {
    createRestorePointIfNeeded
    Write-Host "Executing disableGameBar function..."
    Write-GUIOutput "Executing disableGameBar function... (Check console for details)"
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Write-Host "Xbox Game Bar disabled."
    Write-GUIOutput "Xbox Game Bar disabled."
    Write-Host "disableGameBar function completed."
    Write-GUIOutput "disableGameBar function completed."
}

function disableSearchIndexing {
    createRestorePointIfNeeded
    Write-Host "Executing disableSearchIndexing function..."
    Write-GUIOutput "Executing disableSearchIndexing function... (Check console for details)"
    Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveType -eq 3 -and $_.IndexingEnabled -eq $true } | ForEach-Object {
        Write-Host "Disabling indexing on drive $($_.DriveLetter)..."
        $_.IndexingEnabled = $false
        $_.Put() | Out-Null
    }
    Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
    Write-Host "Search Indexing disabled on all local drives."
    Write-GUIOutput "Search Indexing disabled on all local drives."
    Write-Host "disableSearchIndexing function completed."
    Write-GUIOutput "disableSearchIndexing function completed."
}

function cleanTempFiles {
    createRestorePointIfNeeded
    Write-Host "Executing cleanTempFiles function..."
    Write-GUIOutput "Executing cleanTempFiles function... (Check console for details)"
    $tempPaths = @(
        "$env:TEMP\*"
        "$env:SystemRoot\Temp\*"
        "$env:HomeDrive\Users\Default\AppData\Local\Temp\*"
        "$env:HomeDrive\Users\Public\AppData\Local\Temp\*"
    )

    foreach ($path in $tempPaths) {
        Write-Host "Cleaning $path..."
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Cleaning WinSxS (Component Store)..."
    Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase -ErrorAction SilentlyContinue

    Write-Host "Cleaning Windows Update Cache..."
    Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

    Write-Host "Temporary files and system files cleaned."
    Write-GUIOutput "Temporary files and system files cleaned."
    Write-Host "cleanTempFiles function completed."
    Write-GUIOutput "cleanTempFiles function completed."
}

function disableDeliveryOptimization {
    createRestorePointIfNeeded
    Write-Host "Executing disableDeliveryOptimization function..."
    Write-GUIOutput "Executing disableDeliveryOptimization function... (Check console for details)"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DOMaxBackgroundUploadBandwidth" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DOMaxForegroundUploadBandwidth" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Write-Host "Delivery Optimization disabled."
    Write-GUIOutput "Delivery Optimization disabled."
    Write-Host "disableDeliveryOptimization function completed."
    Write-GUIOutput "disableDeliveryOptimization function completed."
}

function disableSuggestedContent {
    createRestorePointIfNeeded
    Write-Host "Executing disableSuggestedContent function..."
    Write-GUIOutput "Executing disableSuggestedContent function... (Check console for details)"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338390Enabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338391Enabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Write-Host "Suggested content and tips disabled."
    Write-GUIOutput "Suggested content and tips disabled."
    Write-Host "disableSuggestedContent function completed."
    Write-GUIOutput "disableSuggestedContent function completed."
}

function clearDNSCache {
    createRestorePointIfNeeded
    Write-Host "Executing clearDNSCache function..."
    Write-GUIOutput "Executing clearDNSCache function... (Check console for details)"
    ipconfig /flushdns
    Write-Host "DNS Cache cleared."
    Write-GUIOutput "DNS Cache cleared."
    Write-Host "clearDNSCache function completed."
    Write-GUIOutput "clearDNSCache function completed."
}

function disableFastStartup {
    createRestorePointIfNeeded
    Write-Host "Executing disableFastStartup function..."
    Write-GUIOutput "Executing disableFastStartup function... (Check console for details)"
    powercfg /h off
    Write-Host "Fast Startup disabled."
    Write-GUIOutput "Fast Startup disabled."
    Write-Host "disableFastStartup function completed."
    Write-GUIOutput "disableFastStartup function completed."
}

function disableAutomaticMaintenance {
    createRestorePointIfNeeded
    Write-Host "Executing disableAutomaticMaintenance function..."
    Write-GUIOutput "Executing disableAutomaticMaintenance function... (Check console for details)"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" -Name "MaintenanceDisabled" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
    Write-Host "Automatic Maintenance disabled."
    Write-GUIOutput "Automatic Maintenance disabled."
    Write-Host "disableAutomaticMaintenance function completed."
    Write-GUIOutput "disableAutomaticMaintenance function completed."
}

function quickOptimize {
    createRestorePointIfNeeded
    Write-Host "Executing Quick Optimize..."
    Write-GUIOutput "Executing Quick Optimize... (Check console for details)"
    ultimatePowerPlan
    disableUpdates
    disableCortana
    disableTelemetry
    disableTaskbarIcons
    disableAdsTracking
    showFileExtensions
    disableGameBar
    disableSearchIndexing
    cleanTempFiles
    disableDeliveryOptimization
    disableSuggestedContent
    clearDNSCache
    Write-Host "Quick Optimize completed."
    Write-GUIOutput "Quick Optimize completed."
}

function removeDefaultApps {
    createRestorePointIfNeeded
    Write-Host "Executing Remove Default Apps..."
    Write-GUIOutput "Executing Remove Default Apps... (Check console for details)"
    removeEdge
    uninstallUWPApps
    removeOneDrive
    Write-Host "Remove Default Apps completed."
    Write-GUIOutput "Remove Default Apps completed."
}

function massgraveActivation {
    createRestorePointIfNeeded
    Write-Host "Executing Massgrave Windows Activation..."
    Write-GUIOutput "Executing Massgrave Windows Activation... (Check console for details for user input)"
    Invoke-RestMethod https://get.activated.win | Invoke-Expression
    Write-Host "Massgrave Windows Activation completed. Follow on-screen instructions."
    Write-GUIOutput "Massgrave Windows Activation command sent. Follow console instructions."
}

# Install apps using Winget (MODIFIED to accept GUI input from checkboxes)
function installAppsWinget {
    param(
        [System.Windows.Forms.FlowLayoutPanel]$targetFlowPanel # Pass the panel containing checkboxes
    )
    createRestorePointIfNeeded
    Write-Host "Executing Install Apps using Winget..."
    Write-GUIOutput "Executing Install Apps using Winget."

    $selectedAppIDs = @()
    foreach ($control in $targetFlowPanel.Controls) {
        if ($control -is [System.Windows.Forms.CheckBox] -and $control.Checked) {
            $selectedAppIDs += $control.Tag # Tag holds the PackageIdentifier
        }
    }

    if ($selectedAppIDs.Count -gt 0) {
        foreach ($appID in $selectedAppIDs) {
            Write-Host "Attempting to install $appID..."
            Write-GUIOutput "Attempting to install $appID..."
            winget install --id $appID --silent --accept-package-agreements --accept-source-agreements -ErrorAction SilentlyContinue
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$appID installed successfully."
                Write-GUIOutput "$appID installed successfully."
            }
            else {
                Write-Host "Failed to install $appID. It might not exist or an error occurred." -ForegroundColor Yellow
                Write-GUIOutput "Failed to install $appID. It might not exist or an error occurred."
            }
        }
    }
    else {
        Write-Host "No App IDs selected. Skipping Winget installation."
        Write-GUIOutput "No App IDs selected. Skipping Winget installation."
    }
    Write-Host "Install Apps using Winget completed."
    Write-GUIOutput "Install Apps using Winget completed."
}

# Function to clear all checkboxes on the Winget tab
function clearWingetSelections {
    param(
        [System.Windows.Forms.TabControl]$nestedTabControl # Pass the nested tab control
    )
    foreach ($tabPage in $nestedTabControl.TabPages) {
        foreach ($control in $tabPage.Controls) {
            if ($control -is [System.Windows.Forms.FlowLayoutPanel]) {
                foreach ($checkBox in $control.Controls) {
                    if ($checkBox -is [System.Windows.Forms.CheckBox]) {
                        $checkBox.Checked = $false
                    }
                }
            }
        }
    }
    Write-GUIOutput "Winget app selections cleared."
}

function disableMoreNonEssentialServices {
    createRestorePointIfNeeded
    Write-Host "Executing disableMoreNonEssentialServices function..."
    Write-GUIOutput "Executing disableMoreNonEssentialServices function... (Check console for details)"

    Set-Service -Name "Fax" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "RemoteRegistry" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "Print Spooler" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "TabletInputService" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "DoSvc" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "cbdhsvc" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "lfsvc" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "XblGameSave" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "XboxGipSvc" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "XboxNetApiSvc" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "GamingServices" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "GamingServicesNet" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "PimIndexMaintenanceSvc" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "UserDataSvc" -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Service -Name "UnistoreSvc" -StartupType Disabled -ErrorAction SilentlyContinue

    Write-Host "Non-essential services disabled."
    Write-GUIOutput "disableMoreNonEssentialServices function completed."
}

function displaySystemInfo {
    Write-Host "Executing displaySystemInfo function..."
    Write-GUIOutput "Executing displaySystemInfo function... (Check console for details)"

    Write-GUIOutput "---- System Information ----"

    try {
        $os = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer
        Write-GUIOutput "OS: $($os.WindowsProductName) (Version $($os.WindowsVersion))"
        Write-GUIOutput "OS Build: $($os.OsHardwareAbstractionLayer)"
    } catch {
        Write-GUIOutput "Error getting OS info: $($_.Exception.Message)"
    }

    try {
        $ramBytes = (Get-ComputerInfo).TotalPhysicalMemory
        $ramGB = [Math]::Round($ramBytes / 1GB, 2)
        Write-GUIOutput "Installed RAM: $($ramGB) GB"
    } catch {
        Write-GUIOutput "Error getting RAM info: $($_.Exception.Message)"
    }

    try {
        $cpu = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name
        Write-GUIOutput "CPU: $($cpu)"
    } catch {
        Write-GUIOutput "Error getting CPU info: $($_.Exception.Message)"
    }

    try {
        Write-GUIOutput "Disk Usage:"
        Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
            $driveLetter = $_.DeviceID
            $totalSizeGB = [Math]::Round($_.Size / 1GB, 2)
            $freeSpaceGB = [Math]::Round($_.FreeSpace / 1GB, 2)
            if ($totalSizeGB -gt 0) {
                $percentageUsed = [Math]::Round((($totalSizeGB - $freeSpaceGB) / $totalSizeGB) * 100, 2)
                Write-GUIOutput "  Drive $($driveLetter): Total $($totalSizeGB) GB, Free $($freeSpaceGB) GB ($($percentageUsed)% used)"
            } else {
                Write-GUIOutput "  Drive $($driveLetter): Total $($totalSizeGB) GB, Free $($freeSpaceGB) GB (N/A % used)"
            }
        }
    } catch {
        Write-GUIOutput "Error getting Disk info: $($_.Exception.Message)"
    }

    Write-GUIOutput "----------------------------"
    Write-GUIOutput "displaySystemInfo function completed."
}


#==============================================================#
#============== GUI (Graphical User Interface) Code ===========#
#==============================================================#

# --- HOME Tab Content (Quick Actions) ---
$quickActionsGroup = New-Object System.Windows.Forms.GroupBox
$quickActionsGroup.Text = "Quick Actions"
$quickActionsGroup.Location = New-Object System.Drawing.Point(10, 10) # Relative to TabPageHome
$quickActionsGroup.Size = New-Object System.Drawing.Size(950, 120) # Increased height
$quickActionsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$quickActionsGroup.ForeColor = $colorPalette.Highlight
$quickActionsGroup.BackColor = $colorPalette.Background
$quickActionsGroup.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$quickActionsGroup.Padding = New-Object System.Windows.Forms.Padding(5)
$homeTabPage.Controls.Add($quickActionsGroup)

$quickActionsFlowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$quickActionsFlowPanel.Location = New-Object System.Drawing.Point(5, 25)
$quickActionsFlowPanel.Size = New-Object System.Drawing.Size(940, 90)
$quickActionsFlowPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
$quickActionsFlowPanel.WrapContents = $true
$quickActionsFlowPanel.AutoScroll = $false
$quickActionsFlowPanel.BackColor = $colorPalette.Background
$quickActionsFlowPanel.Margin = New-Object System.Windows.Forms.Padding(0)
$quickActionsFlowPanel.Padding = New-Object System.Windows.Forms.Padding(5)
$quickActionsGroup.Controls.Add($quickActionsFlowPanel)

$homeButtonSize = New-Object System.Drawing.Size(210, 70)

$btnCTT = New-Object System.Windows.Forms.Button
$btnCTT.Text = "Run CTT"
$btnCTT.Size = $homeButtonSize
$btnCTT.BackColor = $colorPalette.Foreground
$btnCTT.ForeColor = $colorPalette.PrimaryText
$btnCTT.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCTT.FlatAppearance.BorderSize = 2
$btnCTT.FlatAppearance.BorderColor = $colorPalette.Highlight
$btnCTT.Margin = New-Object System.Windows.Forms.Padding(5)
$btnCTT.Add_Click({ invokeCTT })
$quickActionsFlowPanel.Controls.Add($btnCTT)

$btnQuickOptimize = New-Object System.Windows.Forms.Button
$btnQuickOptimize.Text = "Quick Optimize"
$btnQuickOptimize.Size = $homeButtonSize
$btnQuickOptimize.BackColor = $colorPalette.Foreground
$btnQuickOptimize.ForeColor = $colorPalette.PrimaryText
$btnQuickOptimize.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnQuickOptimize.FlatAppearance.BorderSize = 2
$btnQuickOptimize.FlatAppearance.BorderColor = $colorPalette.Highlight
$btnQuickOptimize.Margin = New-Object System.Windows.Forms.Padding(5)
$btnQuickOptimize.Add_Click({ quickOptimize })
$quickActionsFlowPanel.Controls.Add($btnQuickOptimize)

$btnRemoveDefaultApps = New-Object System.Windows.Forms.Button
$btnRemoveDefaultApps.Text = "Remove Default Apps"
$btnRemoveDefaultApps.Size = $homeButtonSize
$btnRemoveDefaultApps.BackColor = $colorPalette.Foreground
$btnRemoveDefaultApps.ForeColor = $colorPalette.PrimaryText
$btnRemoveDefaultApps.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRemoveDefaultApps.FlatAppearance.BorderSize = 2
$btnRemoveDefaultApps.FlatAppearance.BorderColor = $colorPalette.Highlight
$btnRemoveDefaultApps.Margin = New-Object System.Windows.Forms.Padding(5)
$btnRemoveDefaultApps.Add_Click({ removeDefaultApps })
$quickActionsFlowPanel.Controls.Add($btnRemoveDefaultApps)

$btnMassgrave = New-Object System.Windows.Forms.Button
$btnMassgrave.Text = "Massgrave Activation"
$btnMassgrave.Size = $homeButtonSize
$btnMassgrave.BackColor = $colorPalette.Foreground
$btnMassgrave.ForeColor = $colorPalette.PrimaryText
$btnMassgrave.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnMassgrave.FlatAppearance.BorderSize = 2
$btnMassgrave.FlatAppearance.BorderColor = $colorPalette.Highlight
$btnMassgrave.Margin = New-Object System.Windows.Forms.Padding(5)
$btnMassgrave.Add_Click({ massgraveActivation })
$quickActionsFlowPanel.Controls.Add($btnMassgrave)


# --- WINGET APP INSTALL Tab Content ---
# Refactored: Define apps by category in a hashtable for clarity
$wingetAppsByCategory = @{
    Browsers = @(
        @{Name="Arc"; ID="TheBrowserCompany.Arc"},
        @{Name="Brave"; ID="Brave.Brave"},
        @{Name="Chrome"; ID="Google.Chrome"},
        @{Name="Chromium"; ID="Chromium.Chromium"},
        @{Name="Edge"; ID="Microsoft.Edge"},
        @{Name="Falkon"; ID="KDE.Falkon"},
        @{Name="Firefox"; ID="Mozilla.Firefox"},
        @{Name="Firefox ESR"; ID="Mozilla.Firefox.ESR"},
        @{Name="Opera"; ID="Opera.Opera"},
        @{Name="Opera GX"; ID="Opera.OperaGX"},
        @{Name="Tor Browser"; ID="TorProject.TorBrowser"},
        @{Name="Ungoogled Chromium"; ID="ungoogled-chromium.ungoogled-chromium"},
        @{Name="Vivaldi"; ID="VivaldiTechnologies.Vivaldi"},
        @{Name="Waterfox"; ID="Waterfox.Waterfox"},
        @{Name="Zen Browser"; ID="Avast.SecureBrowser"}
    );
    Communications = @(
        @{Name="Betterbird"; ID="Betterbird.Betterbird"},
        @{Name="Chatterino"; ID="Chatterino.Chatterino"},
        @{Name="Discord"; ID="Discord.Discord"},
        @{Name="Element"; ID="Element.Element"},
        @{Name="Ferdium"; ID="ferdium.ferdium"},
        @{Name="Franz"; ID="meetfranz.franz"},
        @{Name="Guilded"; ID="Guilded.Guilded"},
        @{Name="Hexchat"; ID="HexChat.HexChat"},
        @{Name="Jami"; ID="Jami.Jami"},
        @{Name="Linphone"; ID="Linphone.Linphone"},
        @{Name="Mattermost"; ID="Mattermost.Desktop"},
        @{Name="Mumble"; ID="Mumble.Mumble"},
        @{Name="QTOX"; ID="qTox.qTox"},
        @{Name="Revolt"; ID="Revolt.Revolt"},
        @{Name="Session"; ID="Session.Session"},
        @{Name="Signal"; ID="Signal.Signal"},
        @{Name="Skype"; ID="Microsoft.Skype"},
        @{Name="Slack"; ID="SlackTechnologies.Slack"},
        @{Name="Teams"; ID="Microsoft.Teams"},
        @{Name="Teams (Classic)"; ID="Microsoft.Teams.Classic"},
        @{Name="Telegram"; ID="Telegram.TelegramDesktop"},
        @{Name="Thunderbird"; ID="Mozilla.Thunderbird"},
        @{Name="Tox"; ID="Tox.Tox"},
        @{Name="Unigram"; ID="Unigram.Unigram"},
        @{Name="Vesktop"; ID="Vesktop.Vesktop"},
        @{Name="Viber"; ID="ViberMedia.Viber"},
        @{Name="Wire"; ID="Wire.Wire"},
        @{Name="Zoom"; ID="Zoom.Zoom"},
        @{Name="Zulip"; ID="Zulip.Zulip"}
    );
    Development = @(
        @{Name="Aegisub"; ID="Aegisub.Aegisub"},
        @{Name="Android Studio"; ID="Google.AndroidStudio"},
        @{Name="Anaconda"; ID="Anaconda.Anaconda3"},
        @{Name="CMake"; ID="CMake.CMake"},
        @{Name="Clink"; ID="ChrisB.Clink"},
        @{Name="DaxStudio"; ID="DaxStudio.DaxStudio"},
        @{Name="DBeaver"; ID="dbeaver.dbeaver"},
        @{Name="Docker Desktop"; ID="Docker.DockerDesktop"},
        @{Name="Eclipse IDE"; ID="EclipseFoundation.EclipseIDE"},
        @{Name="Fast Node Manager"; ID="Schniz.fnm"},
        @{Name="FileZilla"; ID="FileZilla.FileZilla"},
        @{Name="Fiddler Everywhere"; ID="Telerik.FiddlerEverywhere"},
        @{Name="Fork"; ID="Fork.Fork"},
        @{Name="Git"; ID="Git.Git"},
        @{Name="Git Butler"; ID="GitButler.GitButler"},
        @{Name="Git Extensions"; ID="GitExtensions.GitExtensions"},
        @{Name="GitHub CLI"; ID="GitHub.cli"},
        @{Name="GitHub Desktop"; ID="GitHub.GitHubDesktop"},
        @{Name="Gitify"; ID="ManishKumar.Gitify"},
        @{Name="Go"; ID="GoLang.Go"},
        @{Name="Godot Engine"; ID="GodotEngine.GodotEngine"},
        @{Name="Insomnia"; ID="Kong.Insomnia"},
        @{Name="IntelliJ IDEA Community"; ID="JetBrains.IntelliJIDEA.Community"},
        @{Name="Jetbrains Rider"; ID="JetBrains.Rider"},
        @{Name="Jetbrains Toolbox"; ID="JetBrains.Toolbox"},
        @{Name="Lazygit"; ID="LazyGit.LazyGit"},
        @{Name="Miniconda"; ID="CondaForge.Miniconda3"},
        @{Name="MongoDB Compass"; ID="MongoDB.Compass"},
        @{Name="MySQL"; ID="Oracle.MySQL"},
        @{Name="Neovim"; ID="Neovim.Neovim"},
        @{Name="NodeJS"; ID="OpenJSFoundation.Nodejs"},
        @{Name="NodeJS LTS"; ID="OpenJSFoundation.Nodejs.LTS"},
        @{Name="Notepad3"; ID="Rizonesoft.Notepad3"},
        @{Name="Oh My Posh (Prompt)"; ID="JanDeDobbeleer.OhMyPosh"},
        @{Name="Pixi"; ID="prefix.pixi"},
        @{Name="PostgreSQL"; ID="PostgreSQL.PostgreSQL"},
        @{Name="Postman"; ID="Postman.Postman"},
        @{Name="Pulsar"; ID="Pulsar.Pulsar"},
        @{Name="PuTTY"; ID="PuTTY.PuTTY"},
        @{Name="PyCharm Community"; ID="JetBrains.PyCharm.Community"},
        @{Name="Python Version Manager"; ID="pnpm.pnpm"},
        @{Name="Python3"; ID="Python.Python.3"},
        @{Name="Rider"; ID="JetBrains.Rider"},
        @{Name="RubyInstaller"; ID="RubyInstallerTeam.RubyInstaller"},
        @{Name="Rust"; ID="RustLang.Rust"},
        @{Name="Starship (Shell Prompt)"; ID="Starship.Starship"},
        @{Name="Sublime Merge"; ID="SublimeHQ.SublimeMerge"},
        @{Name="Sublime Text"; ID="SublimeHQ.SublimeText"},
        @{Name="Swift toolchain"; ID="Swift.Swift"},
        @{Name="Thonny Python IDE"; ID="Thonny.Thonny"},
        @{Name="Unity Game Engine"; ID="Unity.UnityHub"},
        @{Name="Vagrant"; ID="HashiCorp.Vagrant"},
        @{Name="Visual Studio 2022"; ID="Microsoft.VisualStudio.2022.Enterprise"},
        @{Name="Visual Studio (Community)"; ID="Microsoft.VisualStudio.2022.Community"},
        @{Name="VS Code"; ID="Microsoft.VisualStudioCode"},
        @{Name="VS Codium"; ID="VSCodium.VSCodium"},
        @{Name="Wezterm"; ID="Wez.WezTerm"},
        @{Name="WinSCP"; ID="WinSCP.WinSCP"},
        @{Name="WSL"; ID="Microsoft.WSL"},
        @{Name="XAMPP"; ID="Bitnami.XAMPP"},
        @{Name="Yarn"; ID="Yarn.Yarn"}
    );
    Document = @(
        @{Name="Adobe Acrobat Reader"; ID="Adobe.Acrobat.Reader.64-bit"},
        @{Name="AFFINE"; ID="AFFiNE.AFFiNE"},
        @{Name="Anki"; ID="Anki.Anki"},
        @{Name="Calibre"; ID="Calibre.Calibre"},
        @{Name="Foxit PDF Editor"; ID="Foxit.FoxitPDFEditor"},
        @{Name="Foxit PDF Reader"; ID="Foxit.FoxitPDFReader"},
        @{Name="Joplin (FOSS Notes)"; ID="Joplin.Joplin"},
        @{Name="LibreOffice"; ID="TheDocumentFoundation.LibreOffice"},
        @{Name="Logseq"; ID="Logseq.Logseq"},
        @{Name="massCode (Snippet Manager)"; ID="massCode.massCode"},
        @{Name="Mendeley Reference Manager"; ID="Elsevier.MendeleyReferenceManager"},
        @{Name="NAPS2 (Document Scan)"; ID="NAPS2.NAPS2"},
        @{Name="Notepad++"; ID="Notepad++.Notepad++"},
        @{Name="Obsidian"; ID="Obsidian.Obsidian"},
        @{Name="Okular"; ID="KDE.Okular"},
        @{Name="ONLYOFFICE"; ID="ONLYOFFICE.DesktopEditors"},
        @{Name="PDF24 creator"; ID="PDF24.PDF24Creator"},
        @{Name="PDFgear"; ID="PDFgear.PDFgear"},
        @{Name="PDFSam Basic"; ID="PDFSaM.PDFSaMBasic"},
        @{Name="Typora"; ID="Typora.Typora"},
        @{Name="WPS Office"; ID="Kingsoft.WPSOffice"},
        @{Name="Xournal++"; ID="xournalpp.xournalpp"},
        @{Name="Zim Desktop Wiki"; ID="Zim.ZimDesktopWiki"},
        @{Name="Znote"; ID="Znote.Znote"},
        @{Name="Zotero"; ID="Zotero.Zotero"}
    );
    Media = @(
        @{Name="AIMP"; ID="AIMP.AIMP"},
        @{Name="Audacity"; ID="Audacity.Audacity"},
        @{Name="Blender"; ID="BlenderFoundation.Blender"},
        @{Name="Darktable"; ID="darktable.darktable"},
        @{Name="foobar2000"; ID="PeterPawlowski.foobar2000"},
        @{Name="GIMP"; ID="GIMP.GIMP"},
        @{Name="HandBrake"; ID="HandBrake.HandBrake"},
        @{Name="Inkscape"; ID="Inkscape.Inkscape"},
        @{Name="IrfanView"; ID="IrfanSkiljan.IrfanView"},
        @{Name="Kdenlive"; ID="KDE.Kdenlive"},
        @{Name="Krita"; ID="KDE.Krita"},
        @{Name="MPV"; ID="mpv.io.mpv"},
        @{Name="OBS Studio"; ID="OBSProject.OBSStudio"},
        @{Name="Paint.NET"; ID="dotPDNLLC.PaintDotNet"},
        @{Name="Shotcut"; ID="Meltytech.Shotcut"},
        @{Name="Spotify"; ID="Spotify.Spotify"},
        @{Name="VLC Media Player"; ID="VideoLAN.VLC"}
    );
    Utilities = @(
        @{Name="7-Zip"; ID="7zip.7zip"},
        @{Name="AutoHotkey"; ID="AutoHotkey.AutoHotkey"},
        @{Name="CCleaner"; ID="Piriform.CCleaner"},
        @{Name="CrystalDiskInfo"; ID="CrystalDewWorld.CrystalDiskInfo"},
        @{Name="CrystalDiskMark"; ID="CrystalDewWorld.CrystalDiskMark"},
        @{Name="Ditto"; ID="Ditto.Ditto"},
        @{Name="Everything"; ID="voidtools.Everything"},
        @{Name="FastCopy"; ID="ShiroKuroSoft.FastCopy"},
        @{Name="F.lux"; ID="F.lux.F.lux"},
        @{Name="Greenshot"; ID="Greenshot.Greenshot"},
        @{Name="HWMonitor"; ID="CPUID.HWMonitor"},
        @{Name="PeaZip"; ID="GiorgioTani.PeaZip"},
        @{Name="PowerToys"; ID="Microsoft.PowerToys"},
        @{Name="PowerShell 7"; ID="Microsoft.PowerShell"},
        @{Name="Q-Dir"; ID="NenadHrg.Q-Dir"},
        @{Name="Revo Uninstaller"; ID="VS.RevoGroup.RevoUninstaller"},
        @{Name="Rufus"; ID="Rufus.Rufus"},
        @{Name="ShareX"; ID="ShareX.ShareX"},
        @{Name="Speccy"; ID="Piriform.Speccy"},
        @{Name="TeraCopy"; ID="CodeSector.TeraCopy"},
        @{Name="TreeSize Free"; ID="JAMSoftware.TreeSizeFree"},
        @{Name="Ventoy"; ID="ventoy.Ventoy"},
        @{Name="WinRAR"; ID="RARLab.WinRAR"}
    );
    Security = @(
        @{Name="Bitwarden"; ID="Bitwarden.Bitwarden"},
        @{Name="GlassWire"; ID="GlassWire.GlassWire"},
        @{Name="KeePass"; ID="DominikReichl.KeePass"},
        @{Name="Malwarebytes"; ID="Malwarebytes.Malwarebytes"},
        @{Name="NordVPN"; ID="NordVPN.NordVPN"},
        @{Name="ProtonVPN"; ID="ProtonTechnologies.ProtonVPN"},
        @{Name="VeraCrypt"; ID="IDRIX.VeraCrypt"},
        @{Name="WireGuard"; ID="WireGuard.WireGuard"}
    );
    CloudSync = @(
        @{Name="Dropbox"; ID="Dropbox.Dropbox"},
        @{Name="Google Drive"; ID="Google.Drive"},
        @{Name="MEGAsync"; ID="Mega.MEGAsync"},
        @{Name="Resilio Sync"; ID="Resilio.Sync"},
        @{Name="Syncthing"; ID="Syncthing.Syncthing"}
    );
    Games = @(
        @{Name="Cemu"; ID="Exzap.Cemu"},
        @{Name="Clone Hero"; ID="HeroGHTeam.CloneHero"},
        @{Name="EA App"; ID="ElectronicArts.EAAnticheat"},
        @{Name="Emulation Station"; ID="Albertonas.EmulationStationDesktopEdition"},
        @{Name="Epic Games Launcher"; ID="EpicGames.EpicGamesLauncher"},
        @{Name="GeForce NOW"; ID="NVIDIA.GeForceNOW"},
        @{Name="GOG Galaxy"; ID="GOG.GOGGalaxy"},
        @{Name="Heroic Games Launcher"; ID="HeroicGamesLauncher.HeroicGamesLauncher"},
        @{Name="Itch.io"; ID="itchio.itch"},
        @{Name="Moonlight/GameStream"; ID="Moonlight.Moonlight"},
        @{Name="Playnite"; ID="Playnite.Playnite"},
        @{Name="Prism Launcher"; ID="PrismLauncher.PrismLauncher"},
        @{Name="PS Remote Play"; ID="SonyInteractiveEntertainment.PSRemotePlay"},
        @{Name="SideQuestVR"; ID="SideQuest.SideQuest"},
        @{Name="Steam"; ID="Valve.Steam"},
        @{Name="Sunshine/GameStream"; ID="LizardByte.Sunshine"},
        @{Name="TCNO Account Switcher"; ID="TCNO.TCNOAccountSwitcher"},
        @{Name="Ubisoft Connect"; ID="Ubisoft.Connect"},
        @{Name="Virtual Desktop Streamer"; ID="VirtualDesktop.VirtualDesktopStreamer"},
        @{Name="XEMU"; ID="XboxEmu.Xemu"}
    );
    "Microsoft Tools" = @(
        @{Name="Microsoft Office (365)"; ID="Microsoft.Office"},
        @{Name="Microsoft Power Automate Desktop"; ID="Microsoft.PowerAutomateDesktop"},
        @{Name="Microsoft To Do"; ID="Microsoft.ToDo"},
        @{Name="Microsoft Whiteboard"; ID="Microsoft.MicrosoftWhiteboard"},
        @{Name="Paint.NET"; ID="dotPDNLLC.PaintDotNet"},
        @{Name="PowerToys"; ID="Microsoft.PowerToys"},
        @{Name="Sysinternals Suite"; ID="Microsoft.SysinternalsSuite"},
        @{Name="Visual Studio (Community)"; ID="Microsoft.VisualStudio.2022.Community"},
        @{Name="Windows Terminal"; ID="Microsoft.WindowsTerminal"},
        @{Name="Xbox App"; ID="Microsoft.XboxApp"}
    );
}

# Flatten the hashtable into the array of hashtables with Category property
$wingetAppsData = @()
foreach ($cat in $wingetAppsByCategory.Keys) {
    foreach ($app in $wingetAppsByCategory[$cat]) {
        $wingetAppsData += @{Category=$cat; Name=$app.Name; ID=$app.ID}
    }
}

# Winget Install and Clear Selection buttons (outside nested tabs)
$btnInstallWingetApps = New-Object System.Windows.Forms.Button
$btnInstallWingetApps.Text = "Install Selected Apps"
$btnInstallWingetApps.Location = New-Object System.Drawing.Point(20, 10)
$btnInstallWingetApps.Size = New-Object System.Drawing.Size(180, 40)
$btnInstallWingetApps.BackColor = $colorPalette.Foreground
$btnInstallWingetApps.ForeColor = $colorPalette.PrimaryText
$btnInstallWingetApps.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnInstallWingetApps.FlatAppearance.BorderSize = 2
$btnInstallWingetApps.FlatAppearance.BorderColor = $colorPalette.Highlight
$btnInstallWingetApps.Add_Click({
    # Pass the current active FlowLayoutPanel to the function
    $currentSelectedFlowPanel = $nestedTabControlWinget.SelectedTab.Controls | Where-Object { $_ -is [System.Windows.Forms.FlowLayoutPanel] } | Select-Object -First 1
    if ($currentSelectedFlowPanel) {
        installAppsWinget -targetFlowPanel $currentSelectedFlowPanel
    } else {
        Write-GUIOutput "Error: Could not find the app list panel."
    }
})
$wingetTabPage.Controls.Add($btnInstallWingetApps)

$btnClearWingetSelections = New-Object System.Windows.Forms.Button
$btnClearWingetSelections.Text = "Clear Selection"
$btnClearWingetSelections.Location = New-Object System.Drawing.Point(210, 10)
$btnClearWingetSelections.Size = New-Object System.Drawing.Size(150, 40)
$btnClearWingetSelections.BackColor = $colorPalette.Foreground
$btnClearWingetSelections.ForeColor = $colorPalette.PrimaryText
$btnClearWingetSelections.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearWingetSelections.FlatAppearance.BorderSize = 2
$btnClearWingetSelections.FlatAppearance.BorderColor = $colorPalette.Highlight
$btnClearWingetSelections.Add_Click({
    clearWingetSelections -nestedTabControl $nestedTabControlWinget
})
$wingetTabPage.Controls.Add($btnClearWingetSelections)

# FIX: Create a Panel to act as a colored border for the nested TabControl
$nestedTabControlContainer = New-Object System.Windows.Forms.Panel
$nestedTabControlContainer.Location = New-Object System.Drawing.Point(10, 60)
$nestedTabControlContainer.Size = New-Object System.Drawing.Size(950, 480)
$nestedTabControlContainer.BackColor = $colorPalette.Highlight
$wingetTabPage.Controls.Add($nestedTabControlContainer)

# Nested TabControl for app categories
$nestedTabControlWinget = New-Object System.Windows.Forms.TabControl
$nestedTabControlWinget.Location = New-Object System.Drawing.Point(2, 2)
$nestedTabControlWinget.Size = New-Object System.Drawing.Size(946, 476)
$nestedTabControlWinget.BackColor = $colorPalette.Background
$nestedTabControlWinget.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
$nestedTabControlWinget.ItemSize = New-Object System.Drawing.Size(120, 25)
$nestedTabControlWinget.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$nestedTabControlContainer.Controls.Add($nestedTabControlWinget) # Add to container

# Re-apply custom draw logic for nested tabs
$nestedTabControlWinget.Add_DrawItem({
    param($sender, $e)
    $g = $e.Graphics
    $tabRect = $e.Bounds
    $tabText = $sender.TabPages[$e.Index].Text

    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center

    $tabBackColor = if ($sender.SelectedIndex -eq $e.Index) {
        $colorPalette.Highlight
    } else {
        $colorPalette.TabHeader
    }

    $brush = New-Object System.Drawing.SolidBrush($tabBackColor)
    $g.FillRectangle($brush, $tabRect)

    $font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $textBrush = New-Object System.Drawing.SolidBrush($colorPalette.PrimaryText)
    $g.DrawString($tabText, $font, $textBrush, [System.Drawing.RectangleF]$tabRect, $stringFormat)
})

# Group apps by category and create nested tab pages
$appsByCategory = $wingetAppsData | Group-Object -Property Category | Sort-Object Name # Sort categories alphabetically

$allCheckboxes = @() # To keep track of all checkboxes for clear selection

foreach ($categoryGroup in $appsByCategory) {
    $categoryName = $categoryGroup.Name
    $categoryApps = $categoryGroup.Group | Sort-Object Name # Sort apps alphabetically within category

    $categoryTabPage = New-Object System.Windows.Forms.TabPage $categoryName
    $categoryTabPage.BackColor = $colorPalette.Background
    $categoryTabPage.Padding = New-Object System.Windows.Forms.Padding(20)
    $nestedTabControlWinget.Controls.Add($categoryTabPage)

    $categoryFlowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $categoryFlowPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $categoryFlowPanel.AutoScroll = $true
    $categoryFlowPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
    $categoryFlowPanel.WrapContents = $true
    $categoryFlowPanel.BackColor = $colorPalette.Background
    $categoryFlowPanel.Margin = New-Object System.Windows.Forms.Padding(0)
    $categoryFlowPanel.Padding = New-Object System.Windows.Forms.Padding(5)
    $categoryTabPage.Controls.Add($categoryFlowPanel)

    foreach ($app in $categoryApps) {
        $checkBox = New-Object System.Windows.Forms.CheckBox
        $checkBox.Text = $app.Name
        $checkBox.Tag = $app.ID # Store PackageIdentifier here for installation
        $checkBox.AutoSize = $true
        $checkBox.ForeColor = $colorPalette.PrimaryText
        $checkBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $checkBox.Margin = New-Object System.Windows.Forms.Padding(20, 10, 20, 10)
        $categoryFlowPanel.Controls.Add($checkBox)
        $allCheckboxes += $checkBox
    }
}


# --- ADVANCED OPTIONS Tab Content (Individual Tweaks) ---
$individualTweaksGroup = New-Object System.Windows.Forms.GroupBox
$individualTweaksGroup.Text = "Individual Tweaks"
$individualTweaksGroup.Location = New-Object System.Drawing.Point(10, 10)
$individualTweaksGroup.Size = New-Object System.Drawing.Size(950, 550)
$individualTweaksGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$individualTweaksGroup.ForeColor = $colorPalette.Highlight
$individualTweaksGroup.BackColor = $colorPalette.Background
$individualTweaksGroup.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$individualTweaksGroup.Padding = New-Object System.Windows.Forms.Padding(5)
$advancedTabPage.Controls.Add($individualTweaksGroup)

$individualTweaksTablePanel = New-Object System.Windows.Forms.TableLayoutPanel
$individualTweaksTablePanel.Location = New-Object System.Drawing.Point(5, 25)
$individualTweaksTablePanel.Size = New-Object System.Drawing.Size(940, 500)
$individualTweaksTablePanel.ColumnCount = 4
$individualTweaksTablePanel.RowCount = 0
$individualTweaksTablePanel.GrowStyle = [System.Windows.Forms.TableLayoutPanelGrowStyle]::AddRows
$individualTweaksTablePanel.AutoScroll = $true
$individualTweaksTablePanel.BackColor = $colorPalette.Background
$individualTweaksTablePanel.Margin = New-Object System.Windows.Forms.Padding(0)
$individualTweaksTablePanel.Padding = New-Object System.Windows.Forms.Padding(5)
$individualTweaksTablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 25)))
$individualTweaksTablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 25)))
$individualTweaksTablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 25)))
$individualTweaksTablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 25)))
$individualTweaksGroup.Controls.Add($individualTweaksTablePanel)

$buttonWidth = [int]220
$buttonHeight = [int]55 # FIX: Increased button height to allow for text wrapping

$individualButtons = @(
    @{Text="Raphire Win11Debloat"; Action={invokeRaphire}},
    @{Text="Remove Microsoft Edge"; Action={removeEdge}},
    @{Text="Set Ultimate Power Plan"; Action={ultimatePowerPlan}},
    @{Text="Set Windows Updates to security only"; Action={disableUpdates}},
    @{Text="Disable Windows Defender"; Action={defenderTweaks}},
    @{Text="Uninstall Pre-installed UWP Apps"; Action={uninstallUWPApps}},
    @{Text="Disable Cortana"; Action={disableCortana}},
    @{Text="Disable Telemetry and Data Collection"; Action={disableTelemetry}},
    @{Text="Remove OneDrive Integration"; Action={removeOneDrive}},
    @{Text="Disable Taskbar Icons"; Action={disableTaskbarIcons}},
    @{Text="Disable Targeted Ads and Tracking"; Action={disableAdsTracking}},
    @{Text="Show File Extensions by Default"; Action={showFileExtensions}},
    @{Text="Disable Xbox Game Bar"; Action={disableGameBar}},
    @{Text="Disable Search Indexing"; Action={disableSearchIndexing}},
    @{Text="Clean Temporary and System Files"; Action={cleanTempFiles}},
    @{Text="Disable Delivery Optimization"; Action={disableDeliveryOptimization}},
    @{Text="Disable Suggested Content and Tips"; Action={disableSuggestedContent}},
    @{Text="Clear DNS Cache"; Action={clearDNSCache}},
    @{Text="Disable Fast Startup"; Action={disableFastStartup}},
    @{Text="Disable Automatic Maintenance"; Action={disableAutomaticMaintenance}},
    @{Text="Disable More Non-Essential Services"; Action={disableMoreNonEssentialServices}},
    @{Text="Display System Information"; Action={displaySystemInfo}}
)

foreach ($btnData in $individualButtons) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $btnData.Text
    $btn.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
    $btn.BackColor = $colorPalette.Foreground
    $btn.ForeColor = $colorPalette.PrimaryText
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 2
    $btn.FlatAppearance.BorderColor = $colorPalette.Highlight
    $btn.Margin = New-Object System.Windows.Forms.Padding(5)
    $btn.Add_Click($btnData.Action)
    $individualTweaksTablePanel.Controls.Add($btn)
}

# --- Exit Button ---
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "0. Exit Winzilla"
$exitButton.Size = New-Object System.Drawing.Size(130, 30)
# FIX: Position the button relative to the output box to ensure it's always visible
$exitButton.Location = New-Object System.Drawing.Point(($outputTextBox.Right - $exitButton.Width), ($outputTextBox.Bottom + 10))
$exitButton.BackColor = $colorPalette.Foreground
$exitButton.ForeColor = $colorPalette.WhiteText
$exitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$exitButton.FlatAppearance.BorderColor = [System.Drawing.Color]::Red
$exitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$exitButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$exitButton.add_Click({
    Write-GUIOutput "Exiting Winzilla. Goodbye!"
    cleanTempFiles # Call cleanTempFiles before exiting
    Start-Sleep -Seconds 1 # Keep the window open briefly
    $mainForm.Close()
})
$mainForm.CancelButton = $exitButton
$mainForm.Controls.Add($exitButton)

# --- Show the form ---
$mainForm.ShowDialog() | Out-Null