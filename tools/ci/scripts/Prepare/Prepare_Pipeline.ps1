param(
    [string]$BinariesFolder
    )

    # delete all files in the binaries directory
    Remove-Item "$BinariesFolder\*.*" -Recurse -Force

    if (Test-Path -Path "$BinariesFolder\Binaries")
        { Remove-Item "$BinariesFolder\Binaries\" -Recurse -Force }
        
    if (Test-Path -Path "$BinariesFolder\Temp")
        { Remove-Item "$BinariesFolder\Temp\" -Recurse -Force }

    if (!(Test-Path -Path "$BinariesFolder\Publish"))
        { New-Item -Path $BinariesFolder -Name "Publish" -ItemType Directory -Force }