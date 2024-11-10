    param(
        [string]$Project,
        [string]$SourcesDirectory
        )

    $pathFile = $SourcesDirectory + "\Physical\" + $Project + "\" + "\Hardware.hw"

    Write-Host "File to change: "
    Write-Host $pathFile

    $cplContent = Get-Content $pathFile
    $lineSimulation = '"    <Parameter ID="Simulation" Value="1" />"'
    $lineSimulation = $lineSimulation.TrimStart('""')
    $lineSimulation = $lineSimulation.TrimEnd('""')

    $countLines = 0
    $countNewLines = 0

    foreach($line in $cplContent){
        if ($line -split ' ' -ccontains 'ID="Simulation"'){
            Write-Host "Simulation has already been activated"
            Exit
        } else {
            $countLines++
        }
    }

    Write-Host "-------------------------------------"
    Write-Host "Activating simulation"
    Write-Host "-------------------------------------"
    Write-Host "--> Delete original file"
    Remove-Item -Path $pathFile

    foreach($line in $cplContent){
        $countNewLines++
        if ($line -split ' ' -ccontains 'ID="ConfigVersion"'){
            $newLine = $line + "`r`n" + $lineSimulation
            Write-Host "--> Write simulation"
            Out-File -FilePath $pathFile -InputObject $newLine -Append -Encoding utf8

        } else {
            if (!($firstRun -like "done")) {
                Write-Host "--> Create new file"
                $firstRun = "done"
            }
            if ($countLines -eq $countNewLines){
                Out-File -FilePath $pathFile -InputObject $line -Append -Encoding utf8 -NoNewline
                Write-Host "--> Finish, close new file"
            } else {
                Out-File -FilePath $pathFile -InputObject $line -Append -Encoding utf8
            }
            
        }
    }