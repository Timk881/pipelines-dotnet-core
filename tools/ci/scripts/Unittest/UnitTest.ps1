param(
    [string]$Name,
    [string]$ResultPath
    )

# call localhost with test environment and convert the result into xml
$Test = Invoke-WebRequest -Uri http://127.0.0.1/WsTest/$Name -UseBasicParsing
$TestResult = ($Test.Content)

# form the file name
$FileName = 'TEST_' + $Name

# create a result file at the TestResults folder
Out-File -FilePath $ResultPath\TestResults\$FileName.xml -InputObject $TestResult -Force -Encoding ASCII

# write an info
$Output = 'File ' + $FileName + '.xml is created at ' + $ResultPath + '\TestResults'
Write-Host $Output