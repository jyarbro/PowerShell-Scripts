Set-Location -Path $HOME

$scriptDir = "$PSScriptRoot\my-scripts"
Get-ChildItem -Path $scriptDir -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}
