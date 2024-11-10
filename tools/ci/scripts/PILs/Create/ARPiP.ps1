param(
    [string]$Project,
    [string]$Machinetype,
    [string]$CpuType,
    [string]$SourcesDirectory,
    [string]$BinaryDirectory
    )

#building path for RUC and simulation target path
$RUCpath          = '"' + $BinaryDirectory + '\Binaries\' + $Project + '\' + $CpuType + '\RUCPackage\RUCPackage.zip", '
$InstallCondition = '"' + 'InstallMode=ForceInitialInstallation UserFolder=' + "'$SourcesDirectory" + "\Flashcard_Ordner_User\" + "$Machinetype'" + ' OverwriteUserFiles=1"'
$DESTpath         = '"DestinationDirectory=' + "'$BinaryDirectory" + "\Publish\" + $Project + "\PiP" + "'" + '"'

# form complete PIL command
$Pil = "CreatePIP ",$RUCpath,$InstallCondition,', "Default", ','"SupportLegacyAR=1", ',$DESTpath

# create PIL file
Out-File -FilePath $BinaryDirectory\CreateNewARPiP.pil -InputObject $Pil -Force -Encoding ASCII -NoNewLine