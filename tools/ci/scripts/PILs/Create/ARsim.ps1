param(
    [string]$Project,
    [string]$CpuType,
    [switch]$StartSimulation,
    [string]$BinaryDirectory
    )

#building path for RUC and simulation target path
$RUCpath        = '"' + $BinaryDirectory + '\Binaries\' + $Project + '\' + $CpuType + '\RUCPackage\RUCPackage.zip", '
$SIMpath        = '"' + $BinaryDirectory + '\Publish\' + $Project + '\Simulation", '
if ($StartSimulation) {
    $StartCondition = '"Start=1"'
} else {
    $StartCondition = '"Start=0"'
}

# form complete PIL command
$Pil = "CreateARsimStructure ",$RUCpath,$SIMpath,$StartCondition

# create PIL file
Out-File -FilePath $BinaryDirectory\CreateNewARsim.pil -InputObject $Pil -Force -Encoding ASCII -NoNewLine