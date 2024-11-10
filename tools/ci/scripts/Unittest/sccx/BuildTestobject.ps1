#
# BuildTestobject.ps1
#
# Suche der Packages im B&R Projektbaum 
#

function Build-Testobject
{


	param(
		[string]$SourceProject  = $null
	)

	$strTestFolder    = "TestObject"

	if (!$SourceProject)
	{
		Write-LogErr "BuildCoverage : Kein Workspace - Abbruch!"
		Exit -1
	}

	$strSourcePath   = $SourceProject 


	$strLogicalPath   = "$strSourcePath\Logical"
	$strPhysicalPath  = "$strSourcePath\Physical"


	$strSourceFolder  = (Split-Path -Leaf $strSourcePath)
	$strTestPath      = (Split-Path -Parent $strSourcePath) + "\$strTestFolder"

	[System.Collections.ArrayList]$strLogical  = @()
	[System.Collections.ArrayList]$strPhysical = @()


	if (Test-Path $strTestPath )
	{
		Write-Log "Entferne $strTestPath"
		try 
		{
			Remove-item -Path $strTestPath -Recurse -Force
		}
		catch
		{
			$ExceptionMessage = $_.Exception.Message
			Write-LogErr "Build-Testobject : $ExceptionMessage"
			Exit -1
		}
	}

	try 
	{
		$dir =New-Item -Path "$strTestPath" -ItemType Directory
	}
	catch
	{
		$ExceptionMessage = $_.Exception.Message
		Write-LogErr "Build-Testobject : $ExceptionMessage"
		Exit -1
	}
	
	$strLeaf = '\' + (Split-Path -Leaf $strSourcePath) 

	Write-Log "Kopiere Ordner"
	# Dateien aus den Ordnern kopieren - nicht rekursiv!
	Copy-Files -strSource $strSourcePath   -strDestination $strSourcePath.Replace($strLeaf, "\$strTestFolder\")

	Copy-Files -strSource $strLogicalPath  -strDestination $strLogicalPath.Replace($strLeaf, "\$strTestFolder\")

	Copy-Files -strSource $strPhysicalPath -strDestination $strPhysicalPath.Replace($strLeaf, "\$strTestFolder\")

	Write-Log ""
	# Beschreibung aus Logical auslesen
	$Source = Get-Package -strFile "$strLogicalPath\Package.pkg"

	foreach($obj in $Source)
	{
		$strNew = $strLogicalPath + "\" + $obj.InnerText        
		$index  = $strLogical.Add($strNew)
	}

	# Beschreibung aus Physical auslesen    
	$Source = Get-Physical  -strFile "$strPhysicalPath\Physical.pkg"

	foreach($obj in $Source)
	{
		$strNew = $strPhysicalPath + "\" + $obj.InnerText        
		$index  = $strPhysical.Add($strNew)
	}

	#Write-Log ""
	Write-Log "Erstelle Ordner Logical"
	# Ordner Logical im Testobjekt erstellen
	foreach($src in $strLogical)
	{
    
		$dst = $src.Replace($strLeaf, "\$strTestFolder\")
		Write-Log "Kopiere : $dst"
		# Unterordner aus dem Package komplett kopieren   
		Copy-Item -Path $src -Destination $dst -Force -Recurse -Container
	}

	#Write-Log ""
	Write-Log "Erstelle Ordner Physical"
	# Ordner Physical im Testobjekt erstellen
	foreach($src in $strPhysical)
	{
		$dst = $src.Replace($strLeaf, "\$strTestFolder\")
		#Write-Log "Kopiere : $dst"
		# Unterordner aus dem Package komplett kopieren   
		Copy-Item -Path $src -Destination $dst -Force -Recurse -Container
	}

	# ------------------------------------------------------------
	#
	# Suche Attribute Reference in <File> aus Library 
	# Verweisen
	#
	# ------------------------------------------------------------
	Write-Log "Loese restliche Referenzen auf"


	Get-ChildItem -Path "$strTestPath\Logical" -Recurse -Filter "*.pkg" -File  | % {

		$strPath = Split-Path -Parent $_.fullname
		$strFile = Split-Path -Path $_.fullname -Leaf -Resolve

		#Write-Log "Library $strPath\$strFile"

		$xmlContent = New-Object System.XML.XMLDocument

		$xmlContent.Load($_.fullname)

		$xmlRoot  = $xmlContent.Package

		if ($xmlRoot)
		{
			#$files = $xmlRoot.Files.File

			$files = $xmlRoot.Objects.Object | Where-Object Reference -eq "true" 

			foreach ($file in $files)
			{
				$strPath = $file.InnerText
				$strDst  = Split-Path -Parent "$strTestPath$strPath"

   
				if (!(Test-Path $strDst))
				{
					$dir = New-Item -Path $strDst -ItemType Directory
				}  
				Write-Log "    $strPath" 
				Copy-Item -Path "$strSourcePath$strPath" -Destination  "$strTestPath$strPath" -Force
				# Referenzierte Libraries ermitteln
				if ($strPath.EndsWith(".lby") -eq $true )
				{     
					#
					# .lby Dateien k�nnen <Object> und <File> Tags enthalten
					# Daher wird hier in zwei Schritten ausgelesen
					# Schritt 1 : <Objects>
					$library = Get-Library -strFile "$strTestPath$strPath" -objects 

					foreach ($element in $library)
					{
						$src = Split-Path -Parent "$strSourcePath$strPath"
						$src = $src + "\" + $element.innerText
						$dst = Split-Path -Parent "$strTestPath$strPath"
						$dst = $dst + "\" + $element.innerText

						Copy-Item -Path $src -Destination $dst  -Force
					}
					# Schritt 1 : <Files>
					$library = Get-Library -strFile "$strTestPath$strPath" 

					foreach ($element in $library)
					{
						$src = Split-Path -Parent "$strSourcePath$strPath"
						$src = $src + "\" + $element.innerText
						$dst = Split-Path -Parent "$strTestPath$strPath"
						$dst = $dst + "\" + $element.innerText

						Copy-Item -Path $src -Destination $dst  -Force
					}
				}
			}
		}
    
    
	}

	# zum Schluss nochmal alle lby Dateien suchen und dortige Referenzen auslesen
	Get-ChildItem -Path "$strTestPath\Logical" -Recurse -Filter "*.lby" -File  | % {

		$strPath = Split-Path -Parent $_.fullname
		$strFile = Split-Path -Path $_.fullname -Leaf -Resolve

		#Write-Log "Library $strPath\$strFile"

		$xmlContent = New-Object System.XML.XMLDocument

		$xmlContent.Load($_.fullname)

		$xmlRoot  = $xmlContent.Library

		if ($xmlRoot)
		{
			#$files = $xmlRoot.Files.File

			$files = $xmlRoot.Files.File | Where-Object Reference -eq "true" 

			foreach ($file in $files)
			{
				$strRefPath = $file.InnerText
				$strDst  = Split-Path -Parent "$strTestPath$strRefPath"

				#Write-Log "Get-Reference : $strSourcePath$strPath " 

				if (!(Test-Path $strDst))
				{
					$dir = New-Item -Path $strDst -ItemType Directory
				}  
				Copy-Item -Path "$strSourcePath$strRefPath" -Destination  "$strTestPath$strRefPath" -Force
			}

			$xmlRoot.Files.File | % {

				if ($_ -is [string] )
				{                
					$strSrcPath = $strPath.Replace("\$strTestFolder\", "\$strSourceFolder\")
					#Write-Log "    $strSrcPath\$_"
					Copy-Item -Path "$strSrcPath\$_" -Destination  "$strPath\$_" -Force
				}

			}

		}
    
    
	}

	Write-Log "---------------------------------"
	Write-Log "Testobjekt erfolgreich erstellt"
	Write-Log "---------------------------------"

}

# ------------------------------------------------------------
#
# Kopiere alle Dateien im angegebene Ordner in den
# Zielordner
#
# ------------------------------------------------------------
function Copy-Files 
{
    param(
        $strSource,
        $strDestination
    )

    if (!(Test-Path $strDestination))
    {
        $dir = New-Item -Path $strDestination -ItemType Directory
    }


    Get-ChildItem -Path $strSource -Filter "*.*" -File  | % {

	    $strPath = Split-Path -Parent $_.fullname
	    $strFile = Split-Path -Path $_.fullname -Leaf -Resolve

        # Write-Log "Kopiere $strPath\$strFile"
        Copy-Item -Path $_.fullname -Destination "$strDestination\$strFile" -Container
    
    }

}

# ------------------------------------------------------------
#
# Suche <Package> in package Datei 
# Der Eintrag wird im Unterordner Logical verwendet
#
# ------------------------------------------------------------
function Get-Package 
{
	param(
		$strFile
	)

	Write-Log "Get-Package : $strFile"	

	$xmlContent = New-Object System.XML.XMLDocument

	$xmlContent.Load($strFile)

	$xmlRoot  = $xmlContent.Package

    return $xmlRoot.Objects.Object

}

# ------------------------------------------------------------
#
# Suche <Physical> in package Datei
#
# ------------------------------------------------------------
function Get-Physical 
{
	param(
		$strFile
	)

	Write-Log "Get-Physical : $strFile"	

	$xmlContent = New-Object System.XML.XMLDocument

	$xmlContent.Load($strFile)

	$xmlRoot  = $xmlContent.Physical

    return $xmlRoot.Objects.Object

}

# ------------------------------------------------------------
#
# Suche <Library> in IEC.lby Datei 
# Darunter finden sich dann alle Quellcodedateien
#
# ------------------------------------------------------------
function Get-Library 
{
	param(
		[string] $strFile,
        [switch] $objects
	)

	$xmlContent = New-Object System.XML.XMLDocument

	$xmlContent.Load($strFile)

	$xmlRoot  = $xmlContent.Library

    if ($objects -eq $true)
    {
        #Write-Log "Get-Library Objects : $strFile"	
        $elements = $xmlRoot.Objects.Object | Where-Object Type -NE $null | Where-Object Reference -eq $null
    }
    else
    {
        #Write-Log "Get-Library Files : $strFile"	
        $elements = $xmlRoot.Files.File | Where-Object Description -NE $null | Where-Object Reference -eq $null
    }

    return $elements

}

# ------------------------------------------------------------
#
# Suche Attirbute Reference in <Object>
#
# ------------------------------------------------------------
function Get-Reference 
{
	param(
		$strFile
	)

	$xmlContent = New-Object System.XML.XMLDocument

	$xmlContent.Load($strFile)

	$xmlRoot  = $xmlContent.Package

    $objectList = $xmlRoot.Objects.Object | Where-Object Reference -eq "true" 

    $strLang = ""
    $strType = ""

    foreach ($object in $objectList)
    {
        $strLang = $object.getAttribute("Language")
        $strType = $object.getAttribute("Type")

        switch ($strType)
        {
        "Library"
            {
                $strPath = Split-Path -Parent $object.InnerText
                #Write-Log "Get-Reference Library: $strSourcePath$strPath "   
                Copy-Files -strSource "$strSourcePath$strPath"  -strDestination "$strTestPath$strPath"     
            }
        "File"
            {
                $strPath = $object.InnerText
                $strDst  = Split-Path -Parent "$strTestPath$strPath"

               # Write-Log "Get-Reference File : $strSourcePath$strPath " 

                if (!(Test-Path $strDst))
                {
                #    Write-Log "Neuer Ordner $strDst"
                    $dir = New-Item -Path $strDst -ItemType Directory
                }  
                Copy-Item -Path "$strSourcePath$strPath" -Destination  "$strTestPath$strPath" -Force
            }
        }     
    }

}

# ------------------------------------------------------------
#
# Suche Attirbute Reference in <Object>
#
# ------------------------------------------------------------
function Update-Testobject
{
	param(
		$workspace,
		$exportPath
	)

	$Testobject = $workspace
	
	if (!$workspace)
	{
		Write-LogErr "Update-Testobject : kein Workspace angegeben! "
		return -1
	}

	if (!$exportPath)
	{
		$exportPath = Split-Path -Parent $Workspace
	}	
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
	#
	# Ablage eintragen
	#
	#    <Group ID="FileDevice1" />
	#    <Parameter ID="FileDeviceName1" Value="HDD_Temp" />
	#    <Parameter ID="FileDevicePath1" Value="C:\Users\patrickdressel\Documents\Jenkins\BuildServer" />
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$file = "$Testobject\Physical\Basis_UnitTest\Hardware.hw"
	$ns   = 'http://br-automation.co.at/AS/Hardware'

	[xml]$xmlHardware   = Get-Content $file

	$Module = $xmlHardware.Hardware.Module | Where {$_.GetAttribute("Name") -eq "PC"}

	$Group  = $Module.Group

	$newObject = $xmlHardware.CreateElement("Group", $ns)
	$newObject.SetAttribute("ID", "FileDevice1")
	$newChild = $Module.AppendChild($newObject)

	$newObject = $xmlHardware.CreateElement("Parameter", $ns)
	$newObject.SetAttribute("ID", "FileDeviceName1")
	$newObject.SetAttribute("Value", "HDD_SccX")
	$newChild = $Module.AppendChild($newObject)

	$newObject = $xmlHardware.CreateElement("Parameter", $ns)
	$newObject.SetAttribute("ID", "FileDevicePath1")
	$newObject.SetAttribute("Value", "$exportPath")
	$newChild = $Module.AppendChild($newObject)

	$xmlHardware.Save($file)

	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
	#
	# SccX Lib im Projekt einfuegen
	#
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$file = "$Testobject\Logical\Package.pkg"

	[xml]$xmlPackage    = Get-Content $file

	$Objects = $xmlPackage.Package.Objects

	$newObject = $xmlPackage.CreateElement("Object", "http://br-automation.co.at/AS/Package")

	$newObject.SetAttribute("Type", "Package")
	$newObject.InnerText = "sccx"

	$newChild = $Objects.AppendChild($newObject)

	$xmlPackage.Save($file)

	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
	#
	# Lib und Task eintragen
	#
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$file = "$Testobject\Physical\Basis_UnitTest\PC\Cpu.sw"

	[xml]$xmlSoftware    = Get-Content $file

	# Lib einfuegen
	$Objects = $xmlSoftware.SwConfiguration.Libraries

	$newObject = $xmlSoftware.CreateElement("LibraryObject", "http://br-automation.co.at/AS/SwConfiguration")

	$newObject.SetAttribute("Name",      "SccX")
	$newObject.SetAttribute("Source",    "sccx.SccX.lby")
	$newObject.SetAttribute("Memory",    "UserROM")
	$newObject.SetAttribute("Language",  "ANSIC")
	$newObject.SetAttribute("Debugging", "true")

	$newChild = $Objects.AppendChild($newObject)

	# Task einfuegen
	$newTask = $xmlSoftware.CreateElement("Task", "http://br-automation.co.at/AS/SwConfiguration")
	$newTask.SetAttribute("Name",      "Export")
	$newTask.SetAttribute("Source",    "sccx.Export.prg")
	$newTask.SetAttribute("Memory",    "UserROM")
	$newTask.SetAttribute("Language",  "IEC")
	$newTask.SetAttribute("Debugging", "true")

	$taskClass = $xmlSoftware.SwConfiguration.TaskClass | Where {$_.GetAttribute("Name") -eq "Cyclic#2"}

	$newChild = $taskClass.AppendChild($newTask)

	$xmlSoftware.Save($file)
}

