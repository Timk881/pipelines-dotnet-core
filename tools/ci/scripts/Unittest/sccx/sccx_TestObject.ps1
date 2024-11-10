#
# sccx_TestObject.ps1
#
param(
	[string]$Workspace  = $null,
    [string]$sccxPath   = $null,
    [string]$exportPath = $null
)


cls

Write-Host "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
Write-Host "Starte Testgenerator"
Write-Host "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
Write-Host $Workspace
Write-Host $sccxPath
Write-Host $exportPath

$Testobject = Split-Path -Parent $Workspace
$Testobject = "$Testobject\Testobject"


try
{
. "$PSScriptRoot\Logging.ps1"
. "$PSScriptRoot\BuildTestobject.ps1"
. "$PSScriptRoot\BuildCoverage.ps1"

}
catch
{
	$ExceptionMessage = $_.Exception.Message
	Write-LogErr "sccx : $ExceptionMessage"
	Exit -1
}

$strLog = Split-Path -Parent $Workspace 

Start-LogFile -Path "$strLog\sccx.txt" # -Silent 

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
# Zu testendes Projekt kopieren und Lib einbinden
#
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
Build-Testobject -SourceProject $Workspace

Write-Log "Import : $sccxPath"
Copy-Item -Path $sccxPath -Destination "$Testobject\Logical\" -Container -Recurse

if (!(Test-Path "$Testobject\Logical\sccx"))
{
    Rename-Item -Path "$Testobject\Logical\master" -NewName "$Testobject\Logical\sccx"
}

# Im Testprojekt noch die entsprechenden Pfade und Verweise in
# den Konfigdateien einbauen.
Update-Testobject -workspace $Testobject -exportPath $exportPath

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
# Instrumentierung durchfuehren
#
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
Build-Coverage -TestProject $Testobject -OriginalProject $Workspace

# Logdaten sichern! Vorher wird keine Datei erstellt!!
Stop-LogFile

Write-Host "Testobjekt erfolgreich erstellt!"

