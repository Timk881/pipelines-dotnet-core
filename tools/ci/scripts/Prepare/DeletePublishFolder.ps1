param(
    [string]$BinariesFolder
    )
if (Test-Path -Path "$BinariesFolder\Publish")
    { Remove-Item "$BinariesFolder\Publish\" -Recurse -Force }