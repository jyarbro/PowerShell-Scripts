# Ensure gsudo is installed for elevation without repeated UAC prompts
if (-not (Get-Command gsudo -ErrorAction SilentlyContinue)) {
    Write-Output "Installing gsudo..."
    winget install gerardog.gsudo --accept-package-agreements --accept-source-agreements --silent
}

# Enable gsudo caching to prevent repeated UAC prompts
gsudo cache on -p 0 -d 3600 2>&1 | Out-Null  # Cache for 1 hour, suppress warnings

# Update the winget package database to get the latest versions
Write-Output "Updating winget package sources..."
gsudo winget update 2>&1 | Out-Null  # Suppress unnecessary output

# Get a list of all upgradeable packages using text-based parsing for better compatibility
Write-Output "Checking for available upgrades..."
$upgradable = gsudo pwsh -Command "winget upgrade --include-unknown" | Out-String

# Log raw winget output for debugging
#Write-Output "Raw winget upgrade output:`n$upgradable"

# Remove ANSI escape codes from output to prevent parsing issues
$upgradable = $upgradable -replace "\e\[[0-9;]*m", ""

# Extract package details from text output using a refined regex (allows leading/trailing whitespace)
$upgradeList = $upgradable -split "`n" | ForEach-Object {
    if ($_ -match '^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$' -and $matches[1] -ne 'Name' -and $matches[2] -ne 'Id') {
        [PSCustomObject]@{
            Name             = $matches[1]
            Id               = $matches[2]
            InstalledVersion = $matches[3]
            AvailableVersion = $matches[4]
        }
    }
} | Where-Object { $_ -and $_.Name -ne '' -and $_.Id -ne '' }

if ($upgradeList.Count -eq 0) {
    Write-Output "No upgrades available."
    exit
}

# Track applications that may need to be restarted
$restartNeeded = @()

# Upgrade each package individually using gsudo
Write-Output "Upgrading packages..."
foreach ($pkg in $upgradeList) {
    Write-Output "Upgrading $($pkg.Name) from $($pkg.InstalledVersion) to $($pkg.AvailableVersion)..."
    gsudo winget upgrade --id $pkg.Id --accept-package-agreements --accept-source-agreements --silent
    $restartNeeded += $pkg.Name
}

# Check again if any upgrades failed (i.e., still listed)
Start-Sleep -Seconds 5 # Allow time for installations to finish
$remainingUpgrades = gsudo pwsh -Command "winget upgrade --include-unknown" | Out-String
$remainingUpgrades = $remainingUpgrades -replace "\e\[[0-9;]*m", ""

$failedPackages = $remainingUpgrades -split "`n" | ForEach-Object {
    if ($_ -match '^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$' -and $matches[1] -ne 'Name' -and $matches[2] -ne 'Id') {
        [PSCustomObject]@{
            Name             = $matches[1]
            Id               = $matches[2]
            InstalledVersion = $matches[3]
            AvailableVersion = $matches[4]
        }
    }
} | Where-Object { $_ -and $_.Name -ne '' -and $_.Id -ne '' }

if ($failedPackages.Count -gt 0) {
    Write-Output "The following packages failed to upgrade and will be reinstalled:"
    $failedPackages | ForEach-Object { Write-Output "- $($_.Name) (Installed: $($_.InstalledVersion), Available: $($_.AvailableVersion))" }

    foreach ($pkg in $failedPackages) {
        # Attempt to gracefully close the application first by matching on both Id and Name
        $processes = Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.ProcessName -like "*$($pkg.Id)*" -or $_.ProcessName -like "*$($pkg.Name)*"
        }
        if ($processes) {
            Write-Output "Attempting to gracefully close $($pkg.Name)..."
            $processes | ForEach-Object { $_.CloseMainWindow() | Out-Null }
            Start-Sleep -Seconds 5 # Give it time to close

            # Refresh the list of matching processes
            $processes = Get-Process -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessName -like "*$($pkg.Id)*" -or $_.ProcessName -like "*$($pkg.Name)*"
            }
            if ($processes) {
                $processes | ForEach-Object {
                    Write-Output "$($pkg.Name) did not close, forcing shutdown on process $($_.ProcessName) (ID: $($_.Id))..."
                    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                }
            }
        }

        Write-Output "Ensuring all instances of $($pkg.Name) are stopped before uninstalling..."
        # Attempt to get any remaining matching processes using both Name and Id
        $remaining = Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.ProcessName -like "*$($pkg.Id)*" -or $_.ProcessName -like "*$($pkg.Name)*"
        }
        if ($remaining) {
            $remaining | ForEach-Object {
                Write-Output "Force stopping process $($_.ProcessName) (ID: $($_.Id))..."
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        }

        Write-Output "Uninstalling $($pkg.Name) (Version: $($pkg.InstalledVersion))..."
        gsudo winget uninstall --id $pkg.Id --purge --silent

        Write-Output "Reinstalling $($pkg.Name) (Version: $($pkg.AvailableVersion))..."
        gsudo winget install --id $pkg.Id --accept-package-agreements --accept-source-agreements --silent

        # Mark this package for restart tracking
        $restartNeeded += $pkg.Name
    }
}

Write-Output "Upgrade process completed."

# Display applications that may need manual restarting, filtering out invalid names
$restartNeeded = $restartNeeded | Where-Object { $_ -and $_ -ne 'No' } | Select-Object -Unique
if ($restartNeeded.Count -gt 0) {
    Write-Output "The following applications may need to be restarted manually:"
    $restartNeeded | ForEach-Object { Write-Output "- $_" }
}
