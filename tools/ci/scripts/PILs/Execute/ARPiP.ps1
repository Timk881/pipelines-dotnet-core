   param(
        [string]$Project,
        [string]$AsVersion,
        [string]$BinaryDirectory
        )

    #try to delete the old log file if exists
    if (Test-Path $BinaryDirectory\Log.txt )
    {
        Write-Host "Delete Log.txt"
        Write-Host ""
        try 
        {
            Remove-Item -Path $BinaryDirectory\Log.txt -Force
        }
        catch
        {
            $ExceptionMessage = $_.Exception.Message
            Write-Error "CreateARPiP : $ExceptionMessage"
            Exit -1
        }
    }

    if (!(Test-Path -Path $BinaryDirectory\Publish\$Project)){
        New-Item -Path $BinaryDirectory\Publish -Name $Project -ItemType Directory -Force
    }
    if (!(Test-Path -Path $BinaryDirectory\Publish\$Project\PiP)){
        New-Item -Path $BinaryDirectory\Publish\$Project -Name "PiP" -ItemType Directory -Force
    }

    # show content of .pil file
    Write-Host "--------------------------------------------------------"
    Write-Host "Show Content of PIL which will be execute now: "
    Get-Content -Path "$BinaryDirectory\CreateNewARPiP.pil"
    Write-Host "--------------------------------------------------------"

    # execute PviTransfer
    if ($AsVersion -eq "AS412") {
        Start-Process -FilePath "D:\Ersa\Tools\BrAutomation\PVI\V4.12\PVI\Tools\PVITransfer.\PviTransfer.exe" -ArgumentList "$BinaryDirectory\CreateNewARPiP.pil -silent" -WindowStyle Hidden -Wait -PassThru
    } else {
        Start-Process -FilePath "D:\Ersa\Tools\BrAutomation\PVI\V4.9\PVI\Tools\PVITransfer.\PviTransfer.exe" -ArgumentList "$BinaryDirectory\CreateNewARPiP.pil -silent" -WindowStyle Hidden -Wait -PassThru
    }

    Get-Content $BinaryDirectory\Log.txt
    Write-Output "ARPiP created"