param(
    [string]$Project,
    [string]$CpuType,
    [string]$BinaryDirectory
    )

if (!(Test-Path -Path $BinaryDirectory\Publish\$Project)){
    New-Item -Path $BinaryDirectory\Publish -Name $Project -ItemType Directory -Force
}
if (Test-Path -Path $BinaryDirectory\Binaries\$Project\$CpuType\RUCPackage){
    if (Test-Path -Path $BinaryDirectory\Publish\$Project\RUCPackage ){
        Remove-Item -Path $BinaryDirectory\Publish\$Project\RUCPackage -Recurse -Force
        }
    Move-Item -Path $BinaryDirectory\Binaries\$Project\$CpuType\RUCPackage -Destination $BinaryDirectory\Publish\$Project -Force
    }