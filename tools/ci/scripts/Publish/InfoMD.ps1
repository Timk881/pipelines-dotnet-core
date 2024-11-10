param(
    [string]$Project,
    [string]$CpuType,
    [string]$MachineType,
    [string]$SourcesDirectory,
    [string]$BinaryDirectory
    )

# Fill and manipulate the info.md
$path_ToVersion = $SourcesDirectory + "\Physical\" + $Project + "\" + "Hardware.hw"
$path_ToInfoMD   = $SourcesDirectory + "\Flashcard_Ordner_User\" + $MachineType + "\" + "info.md"
$headline_InfoMD = $MachineType + " - " + $Project

Write-Host "File to change: "
Write-Host $path_ToInfoMD

$cplContent_Version = Get-Content $path_ToVersion
$cplContent_InfoMD = Get-Content $path_ToInfoMD

Write-Host "-------------------------------------"
Write-Host "Fill info.md"
Write-Host "-------------------------------------"

foreach($line in $cplContent_Version){
    if ($line -split ' ' -ccontains 'ID="ConfigVersion"'){
        $splittedLine = $line -split ' '
        foreach ($splittedLineForVersion in $splittedLine){
            if ($splittedLineForVersion -split '=' -ccontains "Value"){
                $version = $splittedLineForVersion -split "Value="
                $finalVersion = $version[1].TrimStart('""')
                $finalVersion = $finalVersion.TrimEnd('""')
            }
        }
    }
}

Write-Host "Delete info.md template"
Remove-Item -Path $path_ToInfoMD

foreach($line in $cplContent_InfoMD){
    if ($line -split ' ' -ccontains '$machineType'){
        $line = $line.Replace('$machineType', $headline_InfoMD)
            }
    if ($line -split ' ' -ccontains '$version'){
        $line = $line.Replace('$version', $finalVersion)
            }
    Write-Host $line
    Out-File -FilePath $path_ToInfoMD -InputObject $line -Append -Encoding utf8
    }

# distribute info.md
$path_ToSimDir      = $BinaryDirectory + "\Publish\" + $Project + "\Simulation"
$path_ToTransferDir = $BinaryDirectory + "\Publish\" + $Project + "\RUCPackage"
$path_ToPiPDir      = $BinaryDirectory + "\Publish\" + $Project + "\PiP"

Write-Host "-------------------------------------"
Write-Host "Distribute info.md"
Write-Host "-------------------------------------"
Write-Host ""
if (Test-Path -Path $path_ToSimDir) {
    Write-Host "to Sim structure"
    Copy-Item -Path $path_ToInfoMD -Destination $path_ToSimDir
}
if (Test-Path -Path $path_ToTransferDir) {
    Write-Host "to Transfer structure"
    Copy-Item -Path $path_ToInfoMD -Destination $path_ToTransferDir
}
if (Test-Path -Path $path_ToPiPDir) {
    Write-Host "to PiP structure"
    Copy-Item -Path $path_ToInfoMD -Destination $path_ToPiPDir
}