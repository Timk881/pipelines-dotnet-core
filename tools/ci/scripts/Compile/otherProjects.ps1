    param(
        [string]$Project,
        [string]$Machinetype,
        [string]$ToolPath,
        [string]$SourcesDirectory,
        [string]$BinaryDirectory
        )
    
    # create new file for debugging
    New-Item $BinaryDirectory\$Project.txt -ItemType File -Force

    # if RevInfo.var available, delete the old one
    if (Test-Path -Path $SourcesDirectory\Logical\Allgemein_Tasks_Basis\Communikation\RevInfo.var)
    { Remove-Item $SourcesDirectory\Logical\Allgemein_Tasks_Basis\Communikation\RevInfo.var -Recurse -Force }
    
    # copy RevInfo.var to the correct place for a successful compilation
    Copy-Item -Path $SourcesDirectory\Logical\Allgemein_Tasks_Basis\Communikation\RevInfo\getRevInfo.var                    -Destination $SourcesDirectory\Logical\Allgemein_Tasks_Basis\Communikation 
    Rename-Item -Path $SourcesDirectory\Logical\Allgemein_Tasks_Basis\Communikation\getRevInfo.var                          -NewName RevInfo.var -Force

    # copy files of machinetype into project directory
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Ersa_Maschine.apj                               -Destination $SourcesDirectory\ 
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Package.pkg                                     -Destination $SourcesDirectory\Logical
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Physical.pkg                                    -Destination $SourcesDirectory\Physical
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\mappView\Package.pkg                            -Destination $SourcesDirectory\Logical\mappView
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\mappView\Widgets\Package.pkg                    -Destination $SourcesDirectory\Logical\mappView\Widgets
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Logical\Allgemein_Task_Basis\Alarm\Package.pkg  -Destination $SourcesDirectory\Logical\Allgemein_Tasks_Basis\Alarm
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Logical\Lib_Common\Lib_Manager\Package.pkg      -Destination $SourcesDirectory\Logical\Lib_Common\Lib_Manager
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Logical\Lib_Common\Lib_DeviceList\Package.pkg   -Destination $SourcesDirectory\Logical\Lib_Common\Lib_DeviceList

    # start build process
    $Build = Start-Process -FilePath "$ToolPath\BR.AS.Build.exe" -ArgumentList "$SourcesDirectory\Ersa_Maschine.apj -c $Project -o $BinaryDirectory\Binaries -t $BinaryDirectory\Temp -all -buildRUCPackage" -RedirectStandardOutput "$BinaryDirectory\$Project.txt" -WindowStyle Hidden -Wait -PassThru
    # show complete compile result
    Get-Content $BinaryDirectory\$Project.txt

    # copy standard files into project directory
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Ersa_Maschine.apj                                        -Destination $SourcesDirectory\ 
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Package.pkg                                              -Destination $SourcesDirectory\Logical
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Physical.pkg                                             -Destination $SourcesDirectory\Physical
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\mappView\Package.pkg                                     -Destination $SourcesDirectory\Logical\mappView
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\mappView\Widgets\Package.pkg                             -Destination $SourcesDirectory\Logical\mappView\Widgets
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Logical\Allgemein_Task_Basis\Alarm\Package.pkg           -Destination $SourcesDirectory\Logical\Allgemein_Tasks_Basis\Alarm
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Logical\Lib_Common\Lib_Manager\Package.pkg               -Destination $SourcesDirectory\Logical\Lib_Common\Lib_Manager
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Logical\Lib_Common\Lib_DeviceList\Package.pkg            -Destination $SourcesDirectory\Logical\Lib_Common\Lib_DeviceList

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