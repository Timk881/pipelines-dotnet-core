param(
    [string]$Project,
    [string]$CpuType,
    [string]$MachineType,
    [string]$Version,
    [string]$SourcesDirectory,
    [string]$BinaryDirectory
    )

# Find actual project version
$path_ToVersion = $SourcesDirectory + "\Physical\" + $Project + "\" + "Hardware.hw"
$cplContent_Version = Get-Content $path_ToVersion

foreach($line in $cplContent_Version){
    if ($line -split ' ' -ccontains 'ID="ConfigVersion"'){
        $splittedLine = $line -split ' '
        foreach ($splittedLineForVersion in $splittedLine){
            if ($splittedLineForVersion -split '=' -ccontains "Value"){
                $splittedVersion = $splittedLineForVersion -split "Value="
                $finalVersion = $splittedVersion[1].TrimStart('""')
                $finalVersion = $finalVersion.TrimEnd('""')
            }
        }
    }
}

# split and fill project version
$projectVersion = $finalVersion.Split('.')
$projectVersionMinor = $projectVersion[1].PadLeft(3,'0')
$projectVersionRevision = $projectVersion[2].PadLeft(3,'0')

# split and fill pipeline version
$pipelineVersion = $Version.Split('_')
$pipelineVersionMinor = $pipelineVersion[1].PadLeft(3,'0')
$pipelineVersionRevision = $pipelineVersion[2].PadLeft(3,'0')

# Comparison
if (($projectVersionMinor -eq $pipelineVersionMinor) -and ($projectVersionRevision -eq $pipelineVersionRevision)){
    Write-Output "Version checked = ok --> indentically"
    exit 0; }
    else {
        if ($projectVersionMinor -ne $pipelineVersionMinor){
            Write-Output "Version checked = not ok --> minor not indentically ( $projectVersionMinor <> $pipelineVersionMinor)"}
        if ($projectVersionRevision -ne $pipelineVersionRevision){
            Write-Output "Version checked = not ok --> revision not indentically ( $projectVersionRevision <> $pipelineVersionRevision)"}
        exit 1; }