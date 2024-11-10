
function New-Result
{

	 param(

		[Parameter(Mandatory=$True)]
		[ValidateLength(5,500)]
		[string]$InfoXmlPath = $null,
		[Parameter(Mandatory=$True)]
		[ValidateLength(5,500)]
		[string]$CoverageXmlPath = $null
	)

	Push-Location $InfoXmlPath 

	[xml]$xmlInfo    = Get-Content "$InfoXmlPath/Info.xml"
	[xml]$xmlTestRun = Get-Content "$CoverageXmlPath/Coverage.xml" 

	if (!$xmlInfo -or !$xmlTestRun)
	{
		Write-Log "Keine Ergebnisse gefunden!"
		Exit -1
	}

	$PackageInfoMap = @{}
	$PouInfoMap   = @{}
	$PouMethodMap = @{}
	$PouResultMap = @{}

	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	#
	# Einlesen der tatsaechlichen Ergebnisse aus dem
	# Testlauf vor der Info.xml um die Branch Auswertung 
	# spaeter berechnen zu koennen.
	#
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$PouList         = $xmlTestRun.Result.POU
	$LinesCovered    = 0
	$BranchesCovered = 0

	foreach($Pou in $PouList)
	{
		$LineInfoMap = @{}

		foreach($Line in $Pou.Line)
		{
			$LineInfoMap.add($Line.Nb, $Line.Count)
			$LinesCovered++
		}

		$PouResultMap.Add($Pou.Id, $LineInfoMap)
	}

	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	#
	# Einlesen der Daten aus der Instrumentierung
	# vor dem Testlauf
	#
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$PouList     = $xmlInfo.Info.POU
	$ProjectName = $xmlInfo.Info.Name
	$SourcePath  = $xmlInfo.Info.Path
	$InfoElement = $xmlInfo.Info

	$LinesValid    = $InfoElement.GetAttribute("Lines-Valid")
	$BranchesValid = $InfoElement.GetAttribute("Branches-Valid")

	Write-Debug "Lines : $LinesValid, Branches : $BranchesValid"

	foreach($Pou in $PouList)
	{
		# Packageliste erstellen
		# Dabei wird jedem Package Pfad die jeweilgen IDs der Quellen 
		# zugewiesen.
		$strPackage = $Pou.Path.Replace("$SourcePath\", "")
		#$strPackage = Split-Path -Path $strPackage -Parent
		$strPackage = $strPackage.Split("\")[0]

		if (!$PackageInfoMap.ContainsKey($strPackage))
		{
			$PackageInfoMap[$strPackage] = "" + $Pou.Id
		}
		else
		{
			$PackageInfoMap[$strPackage] += "," + $Pou.Id
		}
		
		$PouMethodMap = @{}
		$LineInfoMap  = $null
		if ($PouResultMap.ContainsKey($Pou.Id))
		{
			$LineInfoMap =  $PouResultMap[$Pou.Id]
		}

    
		# Zeilen der m�glichen Methoden/Actions...
		foreach($Method in $Pou.Method)
		{
			$LineInfo = @()
			foreach($Line in $Method.Line)
			{
				$LineInfo += ,( @($Line.Nb, $Line.Branch))

				if ($LineInfoMap)
				{
					if ($Line.Branch -eq $true)
					{
						if ($LineInfoMap.ContainsKey($Line.Nb))
						{
							$BranchesCovered++
						}
					}
				}

			} 

			$PouMethodMap.Add($Method.Name, $LineInfo)
		}

		# Alles zusammen zur Baustein Id
		$PouInfoMap.Add($Pou.Id, @($Pou.Name, $Pou.Path, $PouMethodMap))	
	}

	$LineRate = 1
	if ($LinesValid -gt 0)
	{
		$LineRate   = $LinesCovered / $LinesValid
	}

	$BranchRate = 1
	if ($BranchesValid -gt 0)
	{
		$BranchRate = $BranchesCovered / $BranchesValid
	}

	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	#
	# Erstellen der Ergebnisdatei 
	#
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$ResultXml = New-Object System.Xml.XmlTextWriter("$CoverageXmlPath\CoverageResult.xml", $null)

	$ResultXml.Formatting = "Indented"
	$ResultXml.Indentation = 1
	$ResultXml.IndentChar = "`t"

	$strCobertura = "http://cobertura.sourceforge.net/xml/coverage-04.dtd"

	# <coverage lines-valid="7" lines-covered="4" line-rate="0.57" branches-valid="2" branches-covered="1" branch-rate="0.5" timestamp="1500242087605" >
	$ResultXml.WriteStartDocument()
	$m = $ResultXml.gettype().getmethod("WriteDocType")
	$m.Invoke($ResultXml, @("coverage", $null, $strCobertura, $null))

	$ResultXml.WriteStartElement("coverage")
	$ResultXml.WriteAttributeString("lines-valid", "$LinesValid")
	$ResultXml.WriteAttributeString("lines-covered", "$LinesCovered")
	$ResultXml.WriteAttributeString("line-rate", "$LineRate")
	$ResultXml.WriteAttributeString("branches-valid", "$BranchesValid")
	$ResultXml.WriteAttributeString("branches-covered", "$BranchesCovered")
	$ResultXml.WriteAttributeString("branch-rate", "$BranchRate")
	$ResultXml.WriteAttributeString("timestamp", "0")
	$ResultXml.WriteAttributeString("complexity", "0")
	$ResultXml.WriteAttributeString("Version", "0.1")
	#  <sources>
	#    <source>C:\Users\Jenkins\Documents\BuildServer\workspace\1000_CoverageTest</source>
	#  </sources>
	$ResultXml.WriteStartElement("sources")
	$SourcePath = $SourcePath.Replace("\\", "/")
	$SourcePath = $SourcePath.Replace("\", "/")
	$ResultXml.WriteElementString("source", "$SourcePath")
	$ResultXml.WriteEndElement(); # sources

	$ResultXml.WriteStartElement("packages")

	foreach($key in $PackageInfoMap.Keys)
	{
		$PouIdList = $PackageInfoMap[$key]
		$PouIdList = $PouIdList.Split(",")
	

		$ResultXml.WriteStartElement("package")
		$ResultXml.WriteAttributeString("name", "$key")
		$ResultXml.WriteAttributeString("line-Rate", "1.0")
		$ResultXml.WriteAttributeString("branch-Rate", "1.0")
		$ResultXml.WriteAttributeString("complexity", "1.0")

		$ResultXml.WriteStartElement("classes")

		foreach ($Id in $PouIdList)
		{
			#Write-Log "Search Id : "$Id
			$PouInfo   = $PouInfoMap[$Id]
			#  Pruefung ob der Baustein ueberhaupt erfasst wurde

			if ($PouInfo)
			{
				# PouResult enthaelt LineInfoMap{nb, count}
				$PouResult = $PouResultMap[$Id]
				$filePath = $PouInfo[1].Replace("\\", "/")
				$filePath = $filePath.Replace("\", "/")
				$filePath = $filePath.Replace($SourcePath, "")
				#Write-Log "Class : "$Id	
				$ResultXml.WriteStartElement("class")
				$ResultXml.WriteAttributeString("name",  $PouInfo[0])
				$ResultXml.WriteAttributeString("filename", $filePath)
				$ResultXml.WriteAttributeString("line-Rate", "1.0")
				$ResultXml.WriteAttributeString("branch-Rate", "1.0")
				$ResultXml.WriteAttributeString("complexity", "1.0")

				$PouMethodMap = $PouInfo[2]
		         
				$ResultXml.WriteStartElement("methods")

				foreach($element in $PouMethodMap.Keys)
				{
					$ResultXml.WriteStartElement("method")
					$ResultXml.WriteAttributeString("name",  $element)
					$ResultXml.WriteAttributeString("signature", "()V")			
					$ResultXml.WriteAttributeString("line-Rate", "1.0")
					$ResultXml.WriteAttributeString("branch-Rate", "1.0")
		
					$LineInfo = $PouMethodMap[$element]

					$ResultXml.WriteStartElement("lines")
					foreach($Line in $LineInfo)
					{ 
						$ResultXml.WriteStartElement("line")

						$ResultXml.WriteAttributeString("number",  $Line[0])
						$Counter = "0"
       
						if ($PouResult)
						{
							if ($PouResult.Contains($Line[0]))
							{
								$Counter = $PouResult[$Line[0]]
							}
						}
						$ResultXml.WriteAttributeString("hits",  "$Counter")
						#$ResultXml.WriteAttributeString("branch",   $Line[1])
						if ($Line[1] -eq "true")
						{
							$ResultXml.WriteAttributeString("branch",   $Line[1])
							$ResultXml.WriteAttributeString("condition-coverage","50% (1/2)")
						}
				
						$ResultXml.WriteEndElement(); # Line
					}
					$ResultXml.WriteEndElement(); # Lines

					$ResultXml.WriteEndElement(); # method
				}

				$ResultXml.WriteEndElement(); # methods

				$ResultXml.WriteStartElement("lines")

				foreach($element in $PouMethodMap.Keys)
				{
					$LineInfo = $PouMethodMap[$element]

					foreach($Line in $LineInfo)
					{ 
						$ResultXml.WriteStartElement("line")

						$ResultXml.WriteAttributeString("number",  $Line[0])
						$Counter = "0"
       
						if ($PouResult)
						{
							if ($PouResult.Contains($Line[0]))
							{
								$Counter = $PouResult[$Line[0]]
							}
						}
						$ResultXml.WriteAttributeString("hits",  "$Counter")
						#$ResultXml.WriteAttributeString("branch",   $Line[1])
						if ($Line[1] -eq "true")
						{				
							$ResultXml.WriteAttributeString("branch",   $Line[1])
							$ResultXml.WriteAttributeString("condition-coverage","50% (1/2)")
						}
				
						$ResultXml.WriteEndElement(); # Line
					}
			
				}
		
				$ResultXml.WriteEndElement(); # Lines
		
				$ResultXml.WriteEndElement(); # class
			}
			else
			{
				Write-Log "not found"
			}

		}

		$ResultXml.WriteEndElement(); # classes
		$ResultXml.WriteEndElement(); # package
	} # 

	$ResultXml.WriteEndElement(); # packages
	$ResultXml.WriteEndElement(); # coverage
	$ResultXml.WriteEndDocument();

	$ResultXml.Flush();
	$ResultXml.Close();

	Remove-Item -Path "$InfoXmlPath/Info.xml" -Force
	Remove-Item -Path "$CoverageXmlPath/Coverage.xml" -Force

	#Write-Log "Package List"
	#$PackageInfoMap
}