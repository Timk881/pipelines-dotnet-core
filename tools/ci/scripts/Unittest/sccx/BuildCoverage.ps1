
try
{
. "$PSScriptRoot\Exclude.ps1"
}
catch
{
	Write-Log "Error getting Exlude.ps1 "	
}
# +++++++++++++++++++++++++++++++++++++++++++++++
# ST Dateien instrumentieren
# +++++++++++++++++++++++++++++++++++++++++++++++
[string]$strLine             = ""
[string]$strInstrTemplate    = "%1 `n`tLineCovered(%id, %nb); %2"
# End of Code
[string]$strInstrEOC         = "`tLineCovered(%id, %nb);`n %1"
[string]$strSourcePath       = ""

[Int]$LineCounter      = 0
[Int]$LineCounterMax   = 0
[Int]$BranchCounter    = 0
[Int]$FileLineCounter  = 0
[Int]$PouBranchCounter = 0
[Int]$BufferSize       = 0
[string]$strCoverageEntry = '<Line Nb="xxxx" Count="1"/>'

[Int]$FileId        = 0
[Int]$ExitCode      = 0

# Maps
$PouInfoMap      = @{}
$SourceMap       = @{}
$MethodInfoMap   = @{}
# Arrays
# Speichert Zeilennummer und Branch Info ab
$LineInfo      = @()
# einfaches Array das die bereits verwendeten Zeilen
# speichert
$Lines         = @()

$InstCodeProgram           = "^PROGRAM.*"
$InstCodeFunction          = "^FUNCTION .*"
$InstCodeFunctionBlock     = "^FUNCTION_BLOCK .*"
$InstCodeAction            = "^ACTION.*:"
$InstCodeEnd_Action        = "^END_ACTION"
$InstCodeEnd_Program       = "^END_PROGRAM"
$InstCodeEnd_Function      = "^END_FUNCTION"
$InstCodeEnd_FunctionBlock = "^END_FUNCTION_BLOCK"

$RegExMethodBegin = '^(ACTION |PROGRAM |FUNCTION )'
$RegExMethodName  = '(.*?)(:|_CYCLIC |_INIT |_EXIT |.*)'
$RegExMethod      = "(?s)(?<=($RegExMethodBegin))($RegExMethodName)"

$RegExCodeString        = "(?<STRING>(\'.*\'|\`".*\`"))"

$InstrRegExBegin        = "(?<Code>$InstCodeProgram|$InstCodeFunctionBlock|$InstCodeFunction|$InstCodeAction)(?<EOL>.*)"
$InstrRegExEnd          = "(?<Code>$InstCodeEnd_Program|$InstCodeEnd_FunctionBlock|$InstCodeEnd_Function|$InstCodeEnd_Action)"

$InstrRegExLine          = '.*'
$InstrRegExCodeIF        = '[ \)\t]THEN|END_IF;?'
$InstrRegExCodeLOOP      = ' DO(?![A-z])|END_WHILE;?|END_FOR;?'

$InstrRegExCaseZahl      = '([0-9])+(\..)*([0-9])* *:(?!=) *'
$InstrRegExCaseName      = '(\w)?:(?!=)(\w| ?(\n?\r?))'#'(\w)?:(?!=) *'
$InstrRegExCodeCASE      = "$InstrRegExCaseName|$InstrRegExCaseZahl|ELSE|END_CASE;?"

$InstrRegExCode          = "(?<Code>$InstrRegExCodeIF|$InstrRegExCodeCASE|$InstrRegExCodeLOOP)(?<EOL>$InstrRegExLine)"

$RegExMultilineBegin    = '(\(\*(?!.*\*\)))'
$RegExMultilineEnd      = '(?!\(\*).*(\*\))'
$RegExLineComment       = '(?<BEGIN>.*)(?<COMMENT>\/\/.*|\(\*.*\*\).*)'
$RegExComment           = '(\/\/)|(\(\*.*\*\))'

$ExcludeList = Get-ExcludeList
# Regex für die Excludeliste zusammenbauen
$RegexExclude = '('

foreach ($Entry in $ExcludeList) {$RegexExclude += $Entry + "|"}

if ($RegexExclude.EndsWith("|"))
{
   $RegexExclude = $RegexExclude.Remove($RegexExclude.Length-1)
}

$RegexExclude += ')'	


#+++++++++++++++++++++++++++++++++++++++++++++
# Information über Zeilenart/nummer speichern
#
#+++++++++++++++++++++++++++++++++++++++++++++
function Add-LineInfo
{

	param(
		[Parameter(Mandatory=$True)]
		[int]$LineNo,
		[Parameter(Mandatory=$True)]
		[bool]$isBranch
	)

	$script:LineCounter++
	$script:FileLineCounter++

	if ($isBranch -eq $true)
	{
		$script:BranchCounter++
		$script:PouBranchCounter++
	}

	if ($script:LineCounterMax -lt $script:FileLineNumber)
	{
		$script:LineCounterMax = $script:FileLineNumber
	}

	$script:LineInfo += ,( @($LineNo, $isBranch))
	$script:Lines    += ,($LineNo)
}

#+++++++++++++++++++++++++++++++++++++++++++++
# Funktion um Quellcode zu instrumentieren
#
#+++++++++++++++++++++++++++++++++++++++++++++
function Create-Coverage
{
	param(
		[Parameter(Mandatory=$True)]
		[ValidateLength(5,500)]
		[string]$strSrcFile = $null
	)

    if ($strSrcFile)
    {
        Write-Log "Create-Coverage : $strSrcFile"
    }
    
	try
	{	
		$file      = Get-Content $strSrcFile
		$newFile   = ""
		# Dateinamen herausfiltern 
		# string nach dem letzten '\' 
		$strFile = $strSrcFile.Split('\')
		$strFile = $strFile[$strFile.Count-1]
		# erster Methodenname = Bausteinname
		# danach werden die entsprechenden Methodennamen ermitteln
		# falls welche gefunden werden.
		$strMethodName = $strFile#.Replace(".st", "")

        $script:FileId++
		$script:MethodInfoMap    = @{}
		$script:LineInfo         = @()
		$script:FileLineNumber   = 1
		$script:FileLineCounter  = 0
		$script:PouBranchCounter = 0
		$script:Lines            = @()

		$bIsComment = $false
        $isCode = $false

		# gehen wir mal auf die Suche 
		foreach ($strLine in $file)
		{		
			$script:FileLineNumber++;	
            #Write-Log $strLine
			#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			# Unterfunktionen ermitteln
			#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			$strLine | 
			Select-String $RegExMethod -AllMatches |
				%{ $_.Matches } |
				%{ 			
					# vorherige Methode speichern und Lineinfo zurücksetzen					
					$script:MethodInfoMap.Add($strMethodName, $script:LineInfo)					
					$script:LineInfo = @()
					$strMethodName = $_.Value.Replace(":", "") 
					$strMethodName = $strMethodName.Replace(" ", "") 			
					Write-Log "`tMethod : $strMethodName"
				}	

			$strNewCode = $strInstrTemplate.Replace("%id", $script:FileId)
			$strNewCode = $strNewCode.Replace("%nb", $script:FileLineNumber)

    
            if ($IsCode -eq $false)
            {
			    # Code Anfang erkennen
			    if ($strLine -match $InstrRegExBegin)
			    {
				    $strLine = $strLine -replace $InstrRegExBegin , $strNewCode
				    $strLine = $strLine.Replace("%1", $Matches['Code']);
				    $strLine = $strLine.Replace("%2", $Matches['EOL']);
				    Add-LineInfo -LineNo $script:FileLineNumber -isBranch $false
				    $IsCode = $true   
			    } 	
            }
            else
            {
				
				# einzeiligen Kommentar ausschließen
				# $strLine = $strLine -replace $RegExComment , ""
				# mehrzeiligen Kommentar Anfang erkennen
				if (Select-String -InputObject $strLine -Pattern $RegExMultilineBegin)
				{
					$bIsComment = $true
					#Write-Log "Start Kommentar"
				}

				if ($bIsComment -eq $false)
				{
					$strString = $null
					# String voruebergehend entfernen
					# für den Fall das sowas wie "... if blabla then ...." als String
					# im Code steht.
					if ($strLine -match $RegExCodeString)
					{
						$strString = $Matches['STRING']
						$strLine = $strLine.Replace($Matches['STRING'], "'xxxxxxxxx'")	
					}
					# einzeilige Kommentare entfernen und Rest behalten
					if ($strLine -match $RegExLineComment)
					{							
						# Code Ende erkennen
						if (Select-String -InputObject $strLine -Pattern $InstrRegExEnd )
						{
							$bIsCode = $false   
						}
						$strLine = $Matches['BEGIN']
					}
					#Write-Log $strLine
					if ($strLine -match $InstrRegExCode)
					{
						$strLine = $strLine -replace $InstrRegExCode , $strNewCode
						$strLine = $strLine.Replace("%1", $Matches['Code']);
						$strLine = $strLine.Replace("%2", $Matches['EOL']);
						Add-LineInfo -LineNo $script:FileLineNumber -isBranch $false

					}
					# String wiederherstellen
					if ($strString)
					{
						$strLine = $strLine.Replace("'xxxxxxxxx'", $strString)
					}
					
				}
				
				# Mehrzeiligen Kommentar Ende erkennen
				if (Select-String -InputObject $strLine -Pattern $RegExMultilineEnd)
				{
					$bIsComment = $false
					#Write-Log "Ende Kommentar"
				}

				# Code Ende erkennen
				#if (Select-String -InputObject $strLine -Pattern $InstrRegExEnd )
				if ($strLine -match $InstrRegExEnd)
				{	
					$LineNumber = $script:FileLineNumber-1
					# nur instrumentieren wenn nicht schon vorher die Zeile 
					# verwendet wurde.
					if ($script:Lines.Contains($LineNumber) -eq $false)
					{
						# "`tLineCovered(%id, %nb);`n %1"
						$strNewCode = $strInstrEOC.Replace("%id", $script:FileId)
						$strNewCode = $strNewCode.Replace("%nb", $LineNumber)					
						$strLine    = $strLine -replace $InstrRegExEnd , $strNewCode
						$strLine    = $strLine.Replace("%1", $Matches['Code']);
						Add-LineInfo -LineNo $LineNumber -isBranch $false
					}
					$IsCode = $false   
				}
            }

            
            $newFile = $newFile + "$strLine`n"	
        }
		# falls die MethodenInfo hier noch nicht gespeichert wurde... speichern
		# passiert z.B. nach dem letzten Durchlauf.
		if($script:MethodInfoMap.contains($strMethodName) -eq $false)
		{		
			$script:MethodInfoMap.Add($strMethodName, $script:LineInfo);
		}
        # geänderten Quellcode speichern
	    Set-Content -Path $strSrcFile -Value $newFile

		# Daten für die spaetere Info.xml speichern
		# - Id des Bausteins
		# - Name der Datei xxx.TcPou
		# - Pfad zur Datei
		# - Liste der Methoden und instrumentierten Zeilen
		# - Lines-Valid
		# - Branches-Valid
		#Write-Debug "Create-Coverage : Add PouInfoMap $script:PouInfoMap"	
		#foreach ($key in $script:MethodInfoMap.Keys)
		#{
		#	Write-Log $key
		#	Write-Log $script:MethodInfoMap[$key]
		#}

		$script:PouInfoMap.Add($script:FileId, @($strFile, $strSrcFile, $script:MethodInfoMap, $script:FileLineCounter, $script:PouBranchCounter))	

    }
    catch
    {
		Write-Log "Fehler bei Dateizugriff"
		Write-Log $_.Exception.Message
		Write-Log $_.ScriptStackTrace
			
	    $result = -1
    }

    $result
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Info speichern
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Create-Dictionary
{

	param(

		[Parameter(Mandatory=$True)]
		[ValidateLength(5,500)]
		[string]$Workspace = $null,
		[Parameter(Mandatory=$True)]
		[ValidateLength(5,500)]
		[string]$strProjectName = $null,		
		[Parameter(Mandatory=$True)]		
		$PouInfoMap = $null
	)

	Write-Log "Erstelle Info.xml"

	#Remove-Item -Path "Info.xml" -Force

	$InfoXml = New-Object System.Xml.XmlTextWriter("$Workspace\Info.xml", $null)

	$InfoXml.Formatting = "Indented"
	$InfoXml.Indentation = 1
	$InfoXml.IndentChar = "`t"

	$InfoXml.WriteStartDocument()
	$InfoXml.WriteStartElement("Info")
	$InfoXml.WriteAttributeString("Name", "$strProjectName")
	$InfoXml.WriteAttributeString("Path", "$script:strSourcePath\Logical")
	$InfoXml.WriteAttributeString("Lines-Valid", "$script:LineCounter")
	$InfoXml.WriteAttributeString("Branches-Valid", "$script:BranchCounter")

	foreach ($Id in $script:PouInfoMap.Keys)
	{

		$Data       = $PouInfoMap[$Id]
		$strFile    = $Data[0]
		if ($SourceMap.ContainsKey($Id))
		{
			$strPath = $SourceMap[$Id]
		}
		$strPath = "$strPath"
		$strPath = $strPath.Replace("//","/")

		$MethodInfo = $Data[2]

		$InfoXml.WriteStartElement("POU")
		$InfoXml.WriteAttributeString("Id", "$Id")
		$InfoXml.WriteAttributeString("Name", $strFile.Replace(".st", ""))
		$InfoXml.WriteAttributeString("Path", $strPath)
		$InfoXml.WriteAttributeString("Lines-Valid", $Data[3])
		$InfoXml.WriteAttributeString("Branches-Valid", $Data[4])	

		# Berechnung der erforderlichen Buffergroesse 
		$BufferNew = $Data[3] * $script:strCoverageEntry.Length;

		if ($script:Buffersize -lt $BufferNew)
		{
			$script:Buffersize = $BufferNew * 2
			#Write-Host "Buffer = $BufferNew"
		}

		foreach($method in $MethodInfo.keys)
		{
			$InfoXml.WriteStartElement("Method")
			$InfoXml.WriteAttributeString("Name", "$method")

			$LineInfo = $MethodInfo[$method]

			foreach($LineEntry in $LineInfo)
			{
				$InfoXml.WriteStartElement("Line")
				$InfoXml.WriteAttributeString("Nb", $LineEntry[0])
				$strBranch = "false"
				if ($LineEntry[1] -eq $true)
				{
					$strBranch = "true"
				}
				$InfoXml.WriteAttributeString("Branch", $strBranch)
				$InfoXml.WriteEndElement(); # Line
				# Write-Log "   - Line Nb= "$LineEntry[0] + " Branch = "$LineEntry[1]
			}

			$InfoXml.WriteEndElement(); # Method
		}

		$InfoXml.WriteEndElement(); # Pou
	}

	$InfoXml.WriteEndElement(); # Info
	$InfoXml.WriteEndDocument();

	$InfoXml.Flush();
	$InfoXml.Close();

}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Info speichern
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Test-Exclude
{
	param(
		[string]$strFile
		)

    if ($strFile -notmatch $RegexExclude)
    {
        return $true
    }

    return $false
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Instrumentierung durchführen
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Build-Coverage
{

	param(
		[string]$TestProject  = $null,
		[string]$OriginalProject  = $null
	)


	$Index = 0

	if (!$TestProject)
	{
		Write-Log "BuildCoverage : Kein Workspace - Abbruch!"
		Exit -1
	}

	$strTestPath          = $TestProject
	$script:strSourcePath = $OriginalProject

	Write-Log "Starte Instrumentierung : $strTestPath "

	# $script:SourceMap = Get-SourceMap -Workspace $TestProject

	try
	{
		# Bausteine anpassen
		Get-ChildItem $TestProject -Recurse -filter "*.st" | % {
				
			if ((Test-Exclude -strFile $_.fullname) -eq $true)
			{
				$strPath = Split-Path -Parent $_.fullname
				$strFile = Split-Path -Path   $_.fullname -Leaf -Resolve
				$Index++
				$script:ExitCode = Create-Coverage -strSrcFile $_.fullname 	
				$strPath = $strPath.Replace($TestProject, $OriginalProject)
				$SourceMap.Add($Index, "$strPath\$strFile")
			}

		}

		$script:ExitCode = Create-Dictionary -Workspace $strTestPath -strProjectName "TestProjekt" -PouInfoMap $script:PouInfoMap
		
	}
	catch
	{
		Write-Error "Instrumentierung kann nicht erstellt werden"
		Write-Error $_.Exception.Message
		Write-Error $_.ScriptStackTrace
		Exit -1
	}

	# +++++++++++++++++++++++++++++++++++++++++++++++
	# Speicher festlegen
	# +++++++++++++++++++++++++++++++++++++++++++++++
	Write-Log "$Index Datei(en) gefunden."
	Write-Log "$script:LineCounterMax maximale Anzahl an Zeilen."

	$strTestTypePath = $strTestPath +'\Logical\sccx\SccX\Types.typ'
	Write-Log "Aktualisiere $strTestTypePath"

	$strAFiles    = 'AFile_t :ARRAY[0..1]OF SFile_t;'
	$strAFilesNew = 'AFile_t :ARRAY[0..%Idx]OF SFile_t;'
	$strALines    = 'ALines_t :ARRAY[0..1]OF USINT;'
	$strALinesNew = 'ALines_t :ARRAY[0..%Idx]OF USINT;'

	$strAFilesNew = $strAFilesNew.Replace("%Idx", $Index)   
	$strALinesNew = $strALinesNew.Replace("%Idx", $script:LineCounterMax)

	$strContent = Get-Content -Path $strTestTypePath

	$strContent = $strContent.Replace($strAFiles, $strAFilesNew);
	$strContent = $strContent.Replace($strALines, $strALinesNew);

	Set-Content -Value $strContent -Path $strTestTypePath

	$strTestTypePath = $strTestPath +'\Logical\sccx\Export\Types.typ'
	Write-Log "Aktualisiere $strTestTypePath"

	$strABuffer      = 'Buffer : ARRAY[0..1]OF BYTE;'
	$strABufferNew   = 'Buffer : ARRAY[0..%Idx]OF BYTE;'
	$strABufferNew = $strABufferNew.Replace("%Idx", $script:Buffersize)
	
	$strContent = Get-Content -Path $strTestTypePath

	$strContent = $strContent.Replace($strABuffer, $strABufferNew);

	Set-Content -Value $strContent -Path $strTestTypePath
}