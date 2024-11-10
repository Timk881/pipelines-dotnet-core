# global variables
$path_ToProject = "D:\Ersa\SPS\BuR.Basis\"
$path_ToTarget  = "D:\Ersa\Test\GenerateBinaries\"

$configuration = "Basis_CP1585"
$plcType = "X20CP1585"

$Library = "BU_AxCan"
#$Library = "BU_AxAna"
#$Library = "alarm_e5"
#$Library = "BU_AktSens"

#---------------------------------------------------------------------------------------------------
# Searching *.fun, *.typ, *.var + IEC.lby

$path_ToLogical = $path_ToProject + "Logical\"

# find path to the sources at logical folder (*.fun, *.typ, *.var + IEC.lby)
$path_ToSource = Get-ChildItem -Recurse -Filter $Library -Directory -ErrorAction SilentlyContinue -Path $path_ToLogical

if ($path_ToSource.Count -gt 1)
    # more than 1 paths are found, check each path for IEC.lby
    {        $index = 0
        while($path_ToSource.FullName[$index] -ne "")
            {    if (Get-ChildItem -Filter "IEC.lby" -File -ErrorAction SilentlyContinue -Path $path_ToSource.FullName[$index])
                    { $completePath_ToSource = $path_ToSource.FullName[$index]
                        Write-Host $completePath_ToSource
                        break
                    } else {
                            if ($index -gt 20)
                                { break
                                } else {
                                        $index++
                                       }
             }
         }
    #only one path is found, IEC.lby available?
    } else { if (Test-Path -Path $path_ToSource.FullName -Filter "IEC.lby")
                {
                $completePath_ToSource = $path_ToSource.FullName
                Write-Host $completePath_ToSource
                }
           }


#---------------------------------------------------------------------------------------------------
# Read out actual versionfrom IEC.lby

$path_ToIEC = $completePath_ToSource + "\IEC.lby"
$cplContentIEC = Get-Content $path_ToIEC

foreach($line in $cplContentIEC)
        {
          $splittedLine = $line -split " "
           #second split with content we want
          Write-Host $splittedLine[1]
          if ( $splittedLine[1] -split "=" -ccontains 'Version')
            {
              # important is what's behind the "="
              $splittedLine_Version = $splittedLine[1] -split "="

              # delete the " at the beginning and the end of the string
              $version_OfBinary = $splittedLine_Version[1].TrimStart('""')
              $version_OfBinary = $version_OfBinary.TrimEnd('""')

              Write-Host $version_OfBinary
              break
            }
          else { $version_OfBinary = "1.00.0"}

}


#---------------------------------------------------------------------------------------------------
# Creating target folders

$path_WithVersion = "V" + $version_OfBinary

#delete folder if exists
if (Test-Path -Path $path_ToTarget\$Library)
    { Remove-Item -Path $path_ToTarget\$Library -Force -Recurse }

New-Item -Path $path_ToTarget -Force -Name $Library -ItemType Directory
New-Item -Path $path_ToTarget\$Library -Name $path_WithVersion -Force -ItemType Directory
New-Item -Path $path_ToTarget\$Library\$path_WithVersion -Name "SG4" -Force -ItemType Directory
New-Item -Path $path_ToTarget\$Library\$path_WithVersion -Name "SG3" -Force -ItemType Directory
New-Item -Path $path_ToTarget\$Library\$path_WithVersion -Name "SGC" -Force -ItemType Directory


#---------------------------------------------------------------------------------------------------
# Move files (*.fun, *.typ, *.var + IEC.lby) to target folder ($path_ToTarget\$Library\$path_WithVersion)

if (Test-Path -Path $completePath_ToSource -Filter *.fun) 
    {
      Get-ChildItem $completePath_ToSource -Filter *.fun | Copy-Item -Destination $path_ToTarget\$Library\$path_WithVersion -Force -PassThru
    }
if (Test-Path -Path $completePath_ToSource -Filter *.typ) 
    {
      Get-ChildItem $completePath_ToSource -Filter *.typ | Copy-Item -Destination $path_ToTarget\$Library\$path_WithVersion -Force -PassThru
    }
if (Test-Path -Path $completePath_ToSource -Filter *.var) 
    {
      Get-ChildItem $completePath_ToSource -Filter *.var | Copy-Item -Destination $path_ToTarget\$Library\$path_WithVersion -Force -PassThru
    }
if (Test-Path -Path $completePath_ToSource -Filter *.lby) 
    {
      Get-ChildItem $completePath_ToSource -Filter *.lby | Copy-Item -Destination $path_ToTarget\$Library\$path_WithVersion -Force -PassThru
    }
if (Test-Path -Path $completePath_ToSource -Filter *.md) 
    {
      Get-ChildItem $completePath_ToSource -Filter *.md | Copy-Item -Destination $path_ToTarget\$Library\$path_WithVersion -Force -PassThru
    }


#---------------------------------------------------------------------------------------------------
# Prepare IEC.lby and rename to Binary.lby
#   - edit Library line (change Subtype + add description)
#   - change <Objects> and <Object to <Files> and <File
#   - delete *.st files and all packages

# Collect information about library from package.pkg
$path_ToPackage = Split-Path -Path $completePath_ToSource -Parent
$path_ToPackage = $path_ToPackage + "\Package.pkg"
$cplContentPkg = Get-Content $path_ToPackage

foreach($line in $cplContentPkg)
        {
          # " " won't work because a lot of whitespaces appears in each line
          $splittedLine = $line -split "="
          # all behind 'Description' is important
          if ( $splittedLine[2] -split " " -ccontains 'Description')
            {
              # important for the description is what's behind the ">"
              $splittedLine_Temp = $splittedLine[3] -split ">"

              $splittedLine_Description = $splittedLine_Temp[0]

              # split the '<' for getting the library name
              $splittedLine_Temp = $splittedLine_Temp[1] -split "<"
              $splittedLine_Library = $splittedLine_Temp[0]

              # check wanted library with the found one
              if ($splittedLine_Library -ne $Library)
                { $splittedLine_Description = "" }

              Write-Host $splittedLine_Description
            }
        }

# all information collected for creating the 'Binary.lby'

# create the new 'Binary.lby'
New-Item -Path $path_ToTarget\$Library\$path_WithVersion -Name "Binary.lby" -ItemType File

# Read out IEC.lby and create a new file called "Binary.lby"
$path_OfIEC       = $path_ToTarget + "\" + $Library + "\" + $path_WithVersion + "\IEC.lby" 
$path_OfBinaryLby = $path_ToTarget + "\" + $Library + "\" + $path_WithVersion + "\Binary.lby"

$cplContentIEC = Get-Content $path_OfIEC

foreach($line in $cplContentIEC)
        {
          $line = $line.Replace("Object", "File")

          $splittedLine = $line -split " "
           #third split with content we want
          if ( $splittedLine[2] -split "=" -ccontains 'SubType')
            {
              # important is what's behind the "="
              $splittedLine_Subtype = $splittedLine[2] -split "="
              if ($splittedLine_Description -ne "")
                { $newSubtype = $splittedLine_Subtype[0] + '="Binary" Description=' + $splittedLine_Description }
                else
                { $newSubtype = $splittedLine_Subtype[0] + '="Binary"' }
              # now result should be: <Library Version="5.00.0" SubType="Binary" Description="Bibliothek Basic Unit AxIntec" xmlns="http://br-automation.co.at/AS/Library">
              $newBinaryLby = $splittedLine[0] + " " + $splittedLine[1] + " " + $newSubtype + " " + $splittedLine[3]
              Write-Host $newBinaryLby 
            }
           # file (only *.typ, *.var and *.fun, *.st are ignored)
           elseif ($line -match 'Type="File"')
                    { if ($line -match '\.st<\/File>')
                        { # do nothing
                          continue
                        }
                      else 
                        { $newBinaryLby = $line.Replace(' Type="File"', "") }
                    }
           # packages not needed --> ignore line
           elseif ($line -match 'Type="Package"')
                    { # do nothing
                      continue
                    }
           # dependencies available and correct?
           elseif ($line -match 'FileName="')
                    { $minimumVersionFound = 0
                      if ($line -match 'FromVersion="') 
                        { $newFromVersion = " " + $splittedLine[6]
                          $minimumVersionFound = 1}
                      else
                        { $newFromVersion = ' FromVersion="1.00.0"' }

                      if (($line -match 'ToVersion="') -and ($minimumVersionFound -gt 0) )
                        { $newToVersion = " " + $splittedLine[7] }
                      else
                        { $newToVersion = "" }
                      $newBinaryLby = $splittedLine[0] + " " + $splittedLine[1] + " " + $splittedLine[2] + " " + $splittedLine[3] + " " + $splittedLine[4] + " " + $splittedLine[5] + $newFromVersion + $newToVersion + " />"
                    }
           else 
            {
              $newBinaryLby = $line
            }

          if ($newBinaryLby -ccontains "</Library>")
            {
              Out-File -FilePath $path_OfBinaryLby -InputObject $newBinaryLby -Force -Encoding utf8 -Append -NoNewline
            } 
          else
            {
              Out-File -FilePath $path_OfBinaryLby -InputObject $newBinaryLby -Force -Encoding utf8 -Append
            }
        }
    Remove-Item -Path $path_OfIEC -Force -Recurse

#---------------------------------------------------------------------------------------------------
# Move files (*.br, *.h, *.a) to target folder ($path_ToTarget\$Library\$path_WithVersion\SG...)

$path_ToBrFile = $path_ToProject + "Binaries\"      + $configuration + "\" + $plcType + "\" + $Library + ".br"
$path_ToAFile  = $path_ToProject + "Temp\Archives\" + $configuration + "\" + $plcType + "\" + "lib" + $Library + ".a"
$path_ToHFile  = $path_ToProject + "Temp\Includes\" + $Library + ".h"

Write-Host $path_ToBrFile
Write-Host $path_ToAFile
Write-Host $path_ToHFile

$path_ToDestinationSG = $path_ToTarget + "\" + $Library + "\" + $path_WithVersion + "\"

# Copy all necessary files in SG4
$path_ToSG4 = $path_ToDestinationSG + "SG4"
Copy-Item -Path $path_ToBrFile -Destination $path_ToSG4 -Force -PassThru
Copy-Item -Path $path_ToAFile  -Destination $path_ToSG4 -Force -PassThru
Copy-Item -Path $path_ToHFile  -Destination $path_ToSG4 -Force -PassThru

# Copy all necessary files in SG3
$path_ToSG3 = $path_ToDestinationSG + "SG3"
Copy-Item -Path $path_ToHFile  -Destination $path_ToSG3 -Force -PassThru

# Copy all necessary files in SGC
$path_ToSGC = $path_ToDestinationSG + "SGC"
Copy-Item -Path $path_ToHFile  -Destination $path_ToSGC -Force -PassThru