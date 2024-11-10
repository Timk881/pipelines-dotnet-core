#
# sccx_Result.ps1
#
param(
	[string]$Workspace     = $null,
	[string]$CoverageFile  = $null
)


cls

if (!$CoverageFile)
{
	$CoverageFile = $Workspace
}

$Testobject = Split-Path -Parent $Workspace
$Testobject = "$Testobject\Testobject"

try
{

. "$PSScriptRoot\BuildResult.ps1"

}
catch
{
	$ExceptionMessage = $_.Exception.Message
	Write-Error "sccx : $ExceptionMessage"
	Exit -1
}

New-Result -InfoXmlPath $Testobject -CoverageXmlPath $CoverageFile
