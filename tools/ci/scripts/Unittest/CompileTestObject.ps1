    param(
        [string]$Project,
        [string]$ToolPath,
        [string]$ToolVersion,
        [string]$SourcesDirectory,
        [string]$BinaryDirectory
        )
    
    # create new file for debugging
    New-Item $BinaryDirectory\$Project.txt -ItemType File -Force

    # find out in which path we working
    $Parent = Split-Path $SourcesDirectory -Parent

    # start build process
    $Build = Start-Process -FilePath "$ToolPath\$ToolVersion\Bin-en.\BR.AS.Build.exe" -ArgumentList "$SourcesDirectory\WorkProject\BasisProject.apj  -c $Project -o $BinaryDirectory\Binaries -t $BinaryDirectory\Temp -all -buildRUCPackage" -RedirectStandardOutput "$BinaryDirectory\$Project.txt" -WindowStyle Hidden -Wait -PassThru
    # show complete compile result
    Get-Content $BinaryDirectory\$Project.txt

    # evaluate exit code
    if($Build.ExitCode -eq 3) {
        Write-Output "Build failed"
        exit 1; }
    if($Build.ExitCode -eq 1) {
        Write-Output "Build executed successfully with warnings"
        exit 0; }
    if($Build.ExitCode -eq 0) {
        Write-Output "Build executed successfully"
        exit 0; }
