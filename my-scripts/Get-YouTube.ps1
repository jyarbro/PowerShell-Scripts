<#
.SYNOPSIS
    Downloads YouTube content using yt-dlp with configurable settings.

.DESCRIPTION
    This function downloads YouTube videos or playlists using yt-dlp.
    It uses two configurable parameters:
      - YT_DLP_PATH: Folder where yt-dlp.exe is located.
      - YT_OUTPUT_DIR: Folder where downloads are saved.
    If these are not provided on the command line, the function will try
    to use the corresponding global variables. If those are not set, then for
    YT_DLP_PATH it defaults to "$env:LOCALAPPDATA\bin\yt-dlp\" and for YT_OUTPUT_DIR
    it will try to use the result of Get-DownloadsPath (if available).
    
    **New:** This function now calls Update-YTDLP to update yt-dlp if a newer release is available.

.PARAMETER Url
    The URL of the YouTube video or playlist to download.
    (Required for download operations.)

.PARAMETER Playlist
    A switch indicating that the provided URL is a playlist.
    When set, the function passes the --yes-playlist flag to yt-dlp.

.PARAMETER Format
    The format selection string for yt-dlp.
    Defaults to:
    "bv*[height<=1080][ext=mp4]+ba[ext=m4a]/b[height<=1080][ext=mp4] / wv*+ba/w"

.PARAMETER YT_DLP_PATH
    Optional. Specifies the path to yt-dlp.exe.
    Overrides the global variable if provided; otherwise, falls back to the global variable,
    and then to the default value "$env:LOCALAPPDATA\bin\yt-dlp\".

.PARAMETER YT_OUTPUT_DIR
    Optional. Specifies the output directory for downloads.
    Overrides the global variable if provided; otherwise, falls back to the global variable,
    then to the result of Get-DownloadsPath if available.
    No fallback is provided if Get-DownloadsPath is unavailable.

.PARAMETER ShowHelp
    Displays this help text.
    Accepts the aliases -? and -Help.

.EXAMPLE
    Get-YouTube -Url "https://www.youtube.com/watch?v=XXXXXX"
    Downloads the specified YouTube video using the configured paths.

.EXAMPLE
    Get-YouTube -Url "https://www.youtube.com/playlist?list=XXXXXX" -Playlist
    Downloads all videos in the specified playlist.

.EXAMPLE
    Get-YouTube -Url "https://www.youtube.com/watch?v=XXXXXX" `
               -YT_DLP_PATH "C:\Custom\yt-dlp" `
               -YT_OUTPUT_DIR "E:\MyDownloads"
    Downloads the specified video using custom paths.

.EXAMPLE
    Get-YouTube -Help 
    or 
    Get-YouTube -?
    Displays the detailed help.
#>
function Get-YouTube {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Url,
        
        [switch]$Playlist,
        
        [string]$Format = "bv*[height<=1080][ext=mp4]+ba[ext=m4a]/b[height<=1080][ext=mp4] / wv*+ba/w",
        
        [string]$YT_DLP_PATH,
        
        [string]$YT_OUTPUT_DIR,
        
        [Alias("?", "Help")]
        [switch]$ShowHelp
    )

    # If help is requested, display it and exit.
    if ($ShowHelp) {
        Get-Help -Detailed $MyInvocation.MyCommand.Name
        return
    }
    
    # Friendly error message if URL is not provided.
    if (-not $Url) {
        Write-Error "Error: The 'Url' parameter is required. Please provide a valid YouTube URL. For usage instructions, use Get-YouTube -Help."
        return
    }
    
    # Determine YT_DLP_PATH:
    if (-not $YT_DLP_PATH) {
        if (Get-Variable -Name YT_DLP_PATH -Scope Global -ErrorAction SilentlyContinue) {
            $YT_DLP_PATH = (Get-Variable -Name YT_DLP_PATH -Scope Global).Value
        }
        else {
            $YT_DLP_PATH = "$env:LOCALAPPDATA\bin\yt-dlp\"
        }
    }
    
    # Determine YT_OUTPUT_DIR:
    if (-not $YT_OUTPUT_DIR) {
        if (Get-Variable -Name YT_OUTPUT_DIR -Scope Global -ErrorAction SilentlyContinue) {
            $YT_OUTPUT_DIR = (Get-Variable -Name YT_OUTPUT_DIR -Scope Global).Value
        }
        else {
            if (Get-Command Get-DownloadsPath -ErrorAction SilentlyContinue) {
                $YT_OUTPUT_DIR = Get-DownloadsPath
            }
        }
    }
    
    # Call Update-YTDLP to update yt-dlp if a newer release is available.
    if (Get-Command Update-YTDLP -ErrorAction SilentlyContinue) {
        Write-Output "Checking for yt-dlp updates..."
        Update-YTDLP -YT_DLP_PATH $YT_DLP_PATH
    }
    else {
        Write-Verbose "Update-YTDLP function not found, skipping update."
    }
    
    # Validate that the directories exist.
    if (-not (Test-Path $YT_DLP_PATH)) {
        Write-Error "Error: The yt-dlp path ($YT_DLP_PATH) does not exist. Please verify YT_DLP_PATH."
        return
    }
    if (-not (Test-Path $YT_OUTPUT_DIR)) {
        Write-Error "Error: The output directory ($YT_OUTPUT_DIR) does not exist. Please verify YT_OUTPUT_DIR."
        return
    }
    
    # Build the argument list for yt-dlp.exe.
    $args = @(
        "--ignore-errors",
        "--extract-audio",
        "--sponsorblock-remove", "all",
        "--keep-video",
        "--output", "$YT_OUTPUT_DIR\%(title)s.%(ext)s"
    )
    
    if ($Playlist) {
        $args += "--yes-playlist"
    }
    
    $args += $Url
    $args += "-f"
    $args += $Format
    
    # Change directory to the yt-dlp installation folder, execute the command, then restore location.
    Push-Location $YT_DLP_PATH
    try {
        & .\yt-dlp.exe @args
    }
    finally {
        Pop-Location
    }
}
