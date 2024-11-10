    param(
        [string]$Project,
        [string]$CpuType,
        [string]$BinaryDirectory
        )

    $pathFile = $BinaryDirectory + "\Binaries\" + $Project + "\" + $CpuType + "\RUCPackage\Transfer.pil"

    Write-Host "File to change: "
    Write-Host $pathFile

    $cplContent = Get-Content $pathFile
    $lineTransfer = 'Transfer "RUCPackage.zip", "InstallMode=ForceInitialInstallation TryToBootInRUNMode=1 ResumeAfterRestart=1"'

    Write-Host "-------------------------------------"
    Write-Host "Correct Transfer.pil"
    Write-Host "-------------------------------------"
    Write-Host "--> Delete original file"
    Remove-Item -Path $pathFile

    $newContent = $cplContent[0] + "`r`n" + $lineTransfer + "`r`n"
    Write-Host $newContent

    Out-File -FilePath $pathFile -InputObject $newContent -Append -Encoding ASCII