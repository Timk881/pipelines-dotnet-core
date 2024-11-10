   param(
        [string]$SourcesDirectory,
        [string]$BinaryDirectory,
        [string]$Toolpath
        )

    #move ExportXML.pil to place of execution 
    Copy-Item -Path "$SourcesDirectory\tools\ci\scripts\Unittest\sccx\ExportXML.pil" -Destination "$BinaryDirectory" -Force

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
            Write-Error "ExportXML : $ExceptionMessage"
            Exit -1
        }
    }

    # show content of .pil file
    Write-Host "--------------------------------------------------------"
    Write-Host "Show Content of PIL which will be execute now: "
    Get-Content -Path "$BinaryDirectory\ExportXML.pil"
    Write-Host "--------------------------------------------------------"
    
    # start PIL for exporting the XML
    Start-Process -FilePath "$ToolPath\PVITransfer.exe" -ArgumentList "$BinaryDirectory\ExportXML.pil -silent" -WindowStyle Hidden -PassThru
    Wait-Process -Name PVITransfer

    # stop PVI Manager
    # Stop-Process -Name PviMan

    # show log
    Get-Content $BinaryDirectory\Log.txt