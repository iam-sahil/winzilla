# Winzilla - Windows Optimization & Debloat Script

## Overview

Winzilla is a powerful PowerShell script designed to optimize, debloat, and secure Windows systems. It provides a menu-driven interface to execute various system tweaks, including disabling Windows Defender, stopping unnecessary Windows updates, and improving system performance.

## Features

- **Administrator Privileges Check**: Ensures the script runs with admin rights and relaunches if necessary.
- **Chris Titus Tech Script Execution**: Runs CTT's optimization script for Windows.
- **Windows 11 Debloat (Raphire)**: Executes a debloating script to remove bloatware.
- **Remove Microsoft Edge**: Downloads and runs a script to uninstall Edge.
- **Ultimate Performance Power Plan**: Activates the highest performance mode.
- **Windows Update Security Optimization**: Stops unnecessary updates and sets them to security-only.
- **Disable Windows Defender**: Disables Windows Defender and related services permanently.

## Installation

To use Winzilla, follow these steps:

1. **Download the script**:
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/iam-sahil/winzilla/refs/heads/master/public/win.ps1" -OutFile "Winzilla.ps1"
   ```

2. **Run the script with administrator privileges**:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; .\Winzilla.ps1
   ```

## Usage

When you run the script, it will display a menu with the following options:

```shell
 __     __     __     __   __     ______     __     __         __         ______    
/\ \  _ \ \   /\ \   /\ "-.\ \   /\___  \   /\ \   /\ \       /\ \       /\  __ \   
\ \ \/ ".\ \  \ \ \  \ \ \-.  \  \/_/  /__  \ \ \  \ \ \____  \ \ \____  \ \  __ \  
 \ \__/".~\_\  \ \_\  \ \_\"\_\   /\_____\   \ \_\  \ \_____\  \ \_____\  \ \_\ \_\
  \/_/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/   \/_____/   \/_____/   \/_/\/_/

Winzilla Menu:
1. Run CTT (Chris Titus Tech Script)
2. Run Raphire Win11Debloat
3. Remove Microsoft Edge
4. Set Ultimate Performance Power Plan
5. Set Windows Updates to security only
6. Disable Windows Defender
0. Exit
```

Enter the corresponding number to execute the desired function.

## Functions Breakdown

### 1. `invokeCTT`
Runs the **Chris Titus Tech** Windows optimization script to tweak and debloat Windows.

### 2. `invokeRaphire`
Executes **Raphire's** Windows 11 Debloat script to remove unnecessary bloatware.

### 3. `removeEdge`
Downloads and runs a batch script to remove Microsoft Edge.

### 4. `ultimatePowerPlan`
Checks if the "Ultimate Performance" power plan is available and activates it if not already in use.

### 5. `disableUpdates`
- Disables automatic driver updates via Windows Update.
- Prevents Windows from automatically restarting for updates.
- Sets updates to **Security Only** mode.

### 6. `defenderTweaks`
- Stops Windows Defender and related services.
- Disables real-time protection and tamper protection.
- Adds all drives to the Windows Defender exclusion list.
- Prevents Windows Defender from re-enabling itself.

## Requirements
- Windows 10 / 11
- PowerShell (Run as Administrator)
- Internet access for script downloads

## Disclaimer
**Use this script at your own risk!** While it is designed to improve system performance and security, modifying system settings can have unintended consequences. Make sure to create a backup before running.

## License
This project is licensed under the MIT License.

## Contributions
Pull requests and improvements are welcome. If you have any suggestions, feel free to submit an issue.

## Author
Developed by **Sahil Rana**.

