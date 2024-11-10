param(
    [string]$ResultFolder
    )

    # create new folder if not existing
    if (!( Test-Path -Path "$ResultFolder\TestResults" ))
        { New-Item -Path "$ResultFolder" -Name "TestResults" -ItemType "directory" -force }

    if (!( Test-Path -Path "$ResultFolder\TestResults\Cobertura" ))
        { New-Item -Path "$ResultFolder\TestResults" -Name "Cobertura" -ItemType "directory" -force }

    # delete all files in the binaries directory and result folders
    Remove-Item "$ResultFolder\*.*"

    if (Test-Path -Path "$ResultFolder\TestResults")
        { Remove-Item "$ResultFolder\TestResults\*.*" }
        
    if (Test-Path -Path "$ResultFolder\TestResults\Cobertura")
        { Remove-Item "$ResultFolder\TestResults\Cobertura\*.*" }