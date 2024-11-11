   param(
        [string]$Toolpath,
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
            Write-Error "BuildAndStartARsim : $ExceptionMessage"
            Exit -1
        }
    }

    # show content of .pil file
    Write-Host "--------------------------------------------------------"
    Write-Host "Show Content of PIL which will be execute now: "
    Get-Content -Path "$BinaryDirectory\CreateNewARsim.pil"
    Write-Host "--------------------------------------------------------"

    # start ARsim
    Start-Process -FilePath "$ToolPath\PviTransfer.exe" -ArgumentList "$BinaryDirectory\CreateNewARsim.pil -silent" -WindowStyle -PassThru

    # giving ARsim the chance to take off
    Start-Sleep -Seconds 30

    # check process of AR000
    $AR000 = Get-Process -Name AR000 -ErrorAction SilentlyContinue

    if ($AR000){ 
        Write-Host 'AR000 running' }
    else { 
        Write-Host 'AR000 not running'
        $ProcessNotWorking = $AR000 -eq $null }

    # check process of AR000Debug
    $AR000Debug = Get-Process -Name AR000Debug -ErrorAction SilentlyContinue

    if ($AR000Debug){ 
        Write-Host 'AR000Debug running' }
    else { 
        Write-Host 'AR000Debug not running'
        $ProcessNotWorking = $AR000Debug -eq $null }

    # check process of ar000loader
    $ar000loader = Get-Process -Name ar000loader -ErrorAction SilentlyContinue

    if ($ar000loader){ 
        Write-Host 'ar000loader running' }
    else { 
        Write-Host 'ar000loader not running'
        $ProcessNotWorking = $ar000loader -eq $null }

    # show log
    Get-Content $BinaryDirectory\Log.txt

    # evaluate exit code
    if($ProcessNotWorking -eq 1) {
        Write-Output 'ARsim is not running'
        exit 1; }
    else {
        Write-Output 'ARsim is running'
        exit 0; }
