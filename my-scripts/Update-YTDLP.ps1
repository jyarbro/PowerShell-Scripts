<#
.SYNOPSIS
    Updates yt-dlp by downloading the latest release from GitHub if it’s newer than the last update.

.DESCRIPTION
    This function queries the GitHub API for the latest yt-dlp release,
    checks the release’s published date against a locally stored timestamp (in last_update.txt),
    and, if the release is newer, downloads and extracts the asset "yt-dlp_win.zip" into your YT_DLP_PATH.
    After a successful update, it writes the release’s published date (in ISO 8601 format)
    to last_update.txt so that subsequent calls can decide whether an update is needed.

.PARAMETER YT_DLP_PATH
    Optional. The folder where yt-dlp.exe should be installed.
    If not provided, the function will use the global variable YT_DLP_PATH if available,
    otherwise it defaults to "$env:LOCALAPPDATA\bin\yt-dlp\".

.EXAMPLE
    Update-YTDLP
    Checks GitHub for the latest yt-dlp release and updates the default YT_DLP_PATH if needed.

.EXAMPLE
    Update-YTDLP -YT_DLP_PATH "C:\Custom\yt-dlp"
    Checks and updates yt-dlp in the specified folder.
#>
function Update-YTDLP {
    [CmdletBinding()]
    param(
        [string]$YT_DLP_PATH
    )

    # Determine the installation path.
    if (-not $YT_DLP_PATH) {
        if (Get-Variable -Name YT_DLP_PATH -Scope Global -ErrorAction SilentlyContinue) {
            $YT_DLP_PATH = (Get-Variable -Name YT_DLP_PATH -Scope Global).Value
        }
        else {
            $YT_DLP_PATH = "$env:LOCALAPPDATA\bin\yt-dlp\"
        }
    }

    # Ensure the destination folder exists.
    if (-not (Test-Path $YT_DLP_PATH)) {
        Write-Verbose "Creating YT_DLP_PATH directory: $YT_DLP_PATH"
        New-Item -Path $YT_DLP_PATH -ItemType Directory -Force | Out-Null
    }

    # Define the path to the file that stores the last update timestamp.
    $lastUpdateFile = Join-Path -Path $YT_DLP_PATH -ChildPath "last_update.txt"
    $lastUpdate = $null

    if (Test-Path $lastUpdateFile) {
        try {
            $lastUpdateContent = Get-Content -Path $lastUpdateFile -ErrorAction Stop
            if ($lastUpdateContent) {
                $lastUpdate = [datetime]::Parse($lastUpdateContent)
            }
        }
        catch {
            Write-Warning "Could not read last update timestamp from $lastUpdateFile. Proceeding with update."
        }
    }

    $releaseApiUrl = "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"

    Write-Output "Fetching latest yt-dlp release information from GitHub..."
    try {
        # GitHub requires a User-Agent header.
        $release = Invoke-RestMethod -Uri $releaseApiUrl -Headers @{ "User-Agent" = "PowerShell" }
    }
    catch {
        Write-Error "Failed to retrieve release information: $_"
        return
    }

    if (-not $release) {
        Write-Error "No release information was returned from GitHub."
        return
    }

    # Get the published date of the release.
    $publishedAt = $release.published_at
    if (-not $publishedAt) {
        Write-Error "Could not determine the published date for the latest release."
        return
    }
    try {
        $releaseDate = [datetime]::Parse($publishedAt)
    }
    catch {
        Write-Error "Failed to parse the release published date: $publishedAt"
        return
    }

    # If a last update exists and is more recent than (or equal to) the release date, skip the update.
    if ($lastUpdate -and $lastUpdate -ge $releaseDate) {
        Write-Output "yt-dlp is already up-to-date. Last update recorded on: $lastUpdate"
        return
    }

    # Look for the asset named "yt-dlp_win.zip".
    $asset = $release.assets | Where-Object { $_.name -eq "yt-dlp_win.zip" }
    if (-not $asset) {
        Write-Error "Could not locate an asset named 'yt-dlp_win.zip' in the latest release."
        return
    }
    $downloadUrl = $asset.browser_download_url
    if (-not $downloadUrl) {
        Write-Error "No download URL was found for 'yt-dlp_win.zip'."
        return
    }

    $tempZip = Join-Path -Path $env:TEMP -ChildPath "yt-dlp_win.zip"
    Write-Output "Downloading yt-dlp from $downloadUrl..."
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -Headers @{ "User-Agent" = "PowerShell" }
    }
    catch {
        Write-Error "Download failed: $_"
        return
    }

    Write-Output "Download complete. Extracting contents to $YT_DLP_PATH..."
    try {
        Expand-Archive -Path $tempZip -DestinationPath $YT_DLP_PATH -Force
    }
    catch {
        Write-Error "Extraction failed: $_"
        return
    }

    # Clean up the temporary zip file.
    Remove-Item -Path $tempZip -Force

    # Write the release date to the last update file in ISO 8601 format.
    try {
        $releaseDate.ToString("o") | Out-File -FilePath $lastUpdateFile -Force
    }
    catch {
        Write-Warning "Failed to update last update timestamp in $lastUpdateFile."
    }

    Write-Output "yt-dlp has been updated successfully in $YT_DLP_PATH."
}
