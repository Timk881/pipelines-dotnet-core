#
# Logging.ps1
#
$strFile    = $null
$LogFile    = $null
$SilentMode = $null
# +++++++++++++++++++++++++++++++++++++++++++++++
# Beginn eines neuen Logs festlegen
# +++++++++++++++++++++++++++++++++++++++++++++++
function Start-Logfile
{
	param(
		[string]$Path   = $null,
		[switch]$Silent
	)

	if ($Silent)
	{
		$script:SilentMode = $true
	}
	$script:strFile = $Path
	$script:LogFile = ""
}

# +++++++++++++++++++++++++++++++++++++++++++++++
# Log In Datei schreibene
# +++++++++++++++++++++++++++++++++++++++++++++++
function Stop-Logfile
{
	if ($script:strFile)
	{
		Set-Content -Value $script:LogFile -Path $script:strFile -Force
	}	
}


# +++++++++++++++++++++++++++++++++++++++++++++++
# Allgemeines Log
# +++++++++++++++++++++++++++++++++++++++++++++++
function Write-Log
{
	param(
		[string]$strLogMessage
	)

	$strLogMessage = "I: $strLogMessage"
	$script:LogFile  = $script:LogFile + "$strLogMessage`n"

	if (!$SilentMode)
	{
		Write-Host "$strLogMessage"
	}
}

# +++++++++++++++++++++++++++++++++++++++++++++++
# Debug Ausgabe
# +++++++++++++++++++++++++++++++++++++++++++++++
function Write-LogDbg
{
	param(
		[string]$strLogMessage
	)

	$strLogMessage = "W: $strLogMessage"
	$script:LogFile  = $script:LogFile + "$strLogMessage`n"

	if (!$SilentMode)
	{
		Write-Host "$strLogMessage"
	}

}

# +++++++++++++++++++++++++++++++++++++++++++++++
# Fehler Ausgabe
# +++++++++++++++++++++++++++++++++++++++++++++++
function Write-LogErr
{
	param(
		[string]$strLogMessage
	)

	$strLogMessage = "E: $strLogMessage"
	$script:LogFile  = $script:LogFile + "$strLogMessage`n"

	Write-Host "$strLogMessage"

}