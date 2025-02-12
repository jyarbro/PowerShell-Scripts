Set-Location -Path $HOME

$scriptDir = "$PSScriptRoot\my-scripts"
Get-ChildItem -Path $scriptDir -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

$global:YT_DLP_PATH   = "$env:LOCALAPPDATA\bin\yt-dlp\"
$global:YT_OUTPUT_DIR = Get-DownloadsPath
