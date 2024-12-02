function checkResult {
param(
    [string]$Testname
)

$FilePath="C:\Users\tkohlert\Desktop\Testagent\_work\2\b\TestResults\$Testname.xml"

[xml]$xmlData = Get-Content -Path $FilePath

    # Testcases
    $totalTestcases = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "TotalTestcases" } | Select-Object -ExpandProperty value
    $succesfullTestcases = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "SuccessfullTestcases" } | Select-Object -ExpandProperty value
    $skippedTestcases = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "SkippedTestcases" } | Select-Object -ExpandProperty value
    # Asserts
    $totalAsserts = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "totalAsserts" } | Select-Object -ExpandProperty value
    $totalAssertsfailures = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "TotalAssertsFailures" } | Select-Object -ExpandProperty value
    $totalAssertspassed = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "TotalAssertsPassed" } | Select-Object -ExpandProperty value
    #Aborts
    $totalAborted = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "TotalAborted" } | Select-Object -ExpandProperty value
    
Write-Output "Debugging TotalTestcases: '$totalTestcases'"
Write-Output "Debugging SuccessfullTestcases: '$successfullTestcases'"

    
  if ($totalAssertsfailures -gt 0) {
        Write-Output "Error ${Testname}: There are failed assertions."
        exit -1
    }

    if ($skippedTestcases -gt 0) {
        Write-Output "Error ${Testname}: There are skipped test cases."
        exit -1
    }

    if ($totalAborted -gt 0) {
        Write-Output "Error ${Testname}: There are aborted tests."
        exit -1
    }

    if ($totalTestcases -ne $successfullTestcases) {
        Write-Output "Error ${Testname}: Not all test cases were successful."
        exit -1
    }

    if ($totalAsserts -ne $totalAssertspassed) {
        Write-Output "Error ${Testname}: Not all assertions passed."
        exit -1
    }

    Write-Output "All of ${Testname} passed successfully!" 

}


checkResult -Testname "TEST_mt_ProcEng"
