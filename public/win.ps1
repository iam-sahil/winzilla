# Check if the script is running with Administrator privileges
$IsAdmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges."
    # Option 1: Relaunch the script as Administrator
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

function invokeCTT {
    Write-Host "Executing invokeCTT function..."
    Invoke-RestMethod https://christitus.com/win | Invoke-Expression
    Write-Host "invokeCTT function completed."
}

# Stop Windows Updates and Set it to security
function disableUpdates {
    Write-Host "Executing disableUpdates function..."
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
    Write-Host "disableUpdates function completed."
}


# Check if the active power plan is not the Ultimate Performance plan
function ultimatePowerPlan {
    Write-Host "Executing ultimatePowerPlan function..."
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
}

# Stop Windows Defender services
function defenderTweaks {
    Write-Host "Executing defenderTweaks function..."
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
        $driveLetter = $drive.Name + ":\"

        Write-Host "Adding $driveLetter to Windows Defender exclusions..."
        Set-MpPreference -ExclusionPath $driveLetter -ErrorAction SilentlyContinue
    }

    Write-Host "All detected drives have been added to Windows Defender exclusions."
    Write-Host "Windows Defender has been disabled permanently."
    Write-Host "defenderTweaks function completed."
}
function removeEdge {
    Write-Host "Running Remove Edge batch script..."

    # URL of the batch script (raw GitHub URL)
    $batchScriptUrl = "https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/setup.exe"

    # Download the batch script content into a variable
    $batchScriptContent = Invoke-WebRequest -Uri $batchScriptUrl -UseBasicPreamble

    # Ensure that the script content is not null or empty
    if ($batchScriptContent) {
        # Convert the content to a temporary file and execute it in memory
        $tempBatchFile = [System.IO.Path]::GetTempFileName()
        $tempBatchFile = $tempBatchFile + ".bat"
        
        # Write the content to the temp file
        Set-Content -Path $tempBatchFile -Value $batchScriptContent.Content
        
        # Now execute the batch file with admin privileges
        Start-Process "cmd.exe" -ArgumentList "/c $tempBatchFile" -Verb RunAs
    }
    else {
        Write-Host "Failed to download the batch script."
    }
}
function invokeRaphire {
    & ([scriptblock]::Create((Invoke-RestMethod "https://debloat.raphi.re/")))    
}
while ($true) {
    Clear-Host
    Write-Host @"
     __     __     __     __   __     ______     __     __         __         ______    
    /\ \  _ \ \   /\ \   /\ "-.\ \   /\___  \   /\ \   /\ \       /\ \       /\  __ \   
    \ \ \/ ".\ \  \ \ \  \ \ \-.  \  \/_/  /__  \ \ \  \ \ \____  \ \ \____  \ \  __ \  
     \ \__/".~\_\  \ \_\  \ \_\\"\_\   /\_____\  \ \_\  \ \_____\  \ \_____\  \ \_\ \_\ 
      \/_/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/   \/_____/   \/_____/   \/_/\/_/ 
"@ -ForegroundColor Green 
    Write-Host ""
    Write-Host "Winzilla Menu:" -ForegroundColor Green
    Write-Host "1. Run CTT (Chris Titus Tech Script)"
    Write-Host "2. Run Raphire Win11Debloat"
    Write-Host "3. Remove Microsoft Edge"
    Write-Host "4. Set Ultimate Performance Power Plan"
    Write-Host "5. Set Windows Updates to security only"
    Write-Host "6. Disable Windows Defender"
    Write-Host "0. Exit"
    Write-Host ""
    Write-Host "Enter your choice (0-6): "

    $choice = Read-Host

    switch ($choice) {
        "1" { invokeCTT }
        "2" { invokeRaphire }
        "3" { removeEdge }
        "4" { ultimatePowerPlan }
        "5" { disableUpdates }
        "6" { defenderTweaks }
        "0" { 
            Clear-Host
            Write-Host "Exiting Winzilla. Goodbye!"-ForegroundColor Green
            exit
        }
        default { Write-Host "Invalid choice. Please enter a number between 0 and 6." }
    }
}
