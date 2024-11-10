#
# Exclude.ps1
#
# Eintraege werden als REGEX interpretiert!
#

function Get-ExcludeList 
{
	$Exclude = ("UnitTesting", `
				"Allgemein_Lib\\Grundelemente\\Lib_ActorSensor\\ActSensEaf\\FB_AktorSensorEaF_TestActions.st", `
				"Allgemein_Lib\\Heizung\\Heiz_Lib\\FB_TempFehler_TestActions.st", `
				"LogDataFifo.st", `
				"sccx")

	$Exclude
}