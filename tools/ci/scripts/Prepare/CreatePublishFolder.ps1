param(
    [string]$BinariesFolder
    )
if (!(Test-Path -Path "$BinariesFolder\Publish"))
    { New-Item -Path $BinariesFolder -Name "Publish" -ItemType Directory -Force }