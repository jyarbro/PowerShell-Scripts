<#
.SYNOPSIS
    Downloads YouTube content using yt-dlp with configurable settings.

.DESCRIPTION
    This function wraps yt-dlp to download videos or playlists. It expects two global variables:
    - YT_DLP_PATH: The folder where yt-dlp.exe is installed.
    - YT_OUTPUT_DIR: The download output directory.
    
    These variables should be set in your PowerShell profile to hide environment-specific details.
    
.PARAMETER Url
    The URL of the YouTube video or playlist.

.PARAMETER Playlist
    A switch indicating that the provided URL is a playlist. When set, the function passes the --yes-playlist
    flag to yt-dlp.

.PARAMETER Format
    The format selection string for yt-dlp. Defaults to a format that selects MP4 video up to 1080p.
    
.EXAMPLE
    Get-YouTube -Url "https://www.youtube.com/playlist?list=XXXXXX" -Playlist
    Downloads all videos in the specified playlist.

.EXAMPLE
    Get-YouTube -Url "https://www.youtube.com/watch?v=XXXXXX"
    Downloads the specified video.
#>
function Get-YouTube {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [switch]$Playlist,

        [Parameter(Mandatory = $false)]
        [string]$Format = "bv*[height<=1080][ext=mp4]+ba[ext=m4a]/b[height<=1080][ext=mp4] / wv*+ba/w"
    )

    begin {
        # Retrieve configuration variables defined in your profile script.
        if (-not (Get-Variable -Name YT_DLP_PATH -Scope Global -ErrorAction SilentlyContinue)) {
            throw "Global variable 'YT_DLP_PATH' is not set. Please set it in your profile script."
        }
        if (-not (Get-Variable -Name YT_OUTPUT_DIR -Scope Global -ErrorAction SilentlyContinue)) {
            throw "Global variable 'YT_OUTPUT_DIR' is not set. Please set it in your profile script."
        }
        $ytDlpPath   = (Get-Variable -Name YT_DLP_PATH -Scope Global).Value
        $ytOutputDir = (Get-Variable -Name YT_OUTPUT_DIR -Scope Global).Value

        # Verify that the directories exist.
        if (-not (Test-Path $ytDlpPath)) {
            throw "The yt-dlp path ($ytDlpPath) does not exist. Please verify YT_DLP_PATH."
        }
        if (-not (Test-Path $ytOutputDir)) {
            throw "The output directory ($ytOutputDir) does not exist. Please verify YT_OUTPUT_DIR."
        }
    }

    process {
        # Build the argument list for yt-dlp.
        $args = @(
            "--ignore-errors",
            "--extract-audio",
            "--sponsorblock-remove", "all",
            "--keep-video",
            "--output", "$ytOutputDir\%(title)s.%(ext)s"
        )

        if ($Playlist) {
            $args += "--yes-playlist"
        }

        $args += $Url
        $args += "-f"
        $args += $Format

        # Change directory to the yt-dlp installation folder, execute, then restore location.
        Push-Location $ytDlpPath
        try {
            & .\yt-dlp.exe @args
        }
        finally {
            Pop-Location
        }
    }
}
