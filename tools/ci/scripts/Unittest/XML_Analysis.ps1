function checkResult {
param(
    [string]$Testname
)

$FilePath="C:\Users\tkohlert\Desktop\Testagent\_work\2\b\TestResults\$Testname.xml"

[xml]$xmlData = Get-Content -Path $FilePath

    # Testcases
    $totalTestCases = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "TotalTestcases" } | Select-Object -ExpandProperty value
    $succesfullTestCases = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "SuccessfullTestcases" } | Select-Object -ExpandProperty value
    $skippedTestCases = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "SkippedTestcases" } | Select-Object -ExpandProperty value
    # Asserts
    $totalAsserts = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "totalAsserts" } | Select-Object -ExpandProperty value
    $TotalAssertsFailures = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "TotalAssertsFailures" } | Select-Object -ExpandProperty value
    $TotalAssertsPassed = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "TotalAssertsPassed" } | Select-Object -ExpandProperty value
    #Aborts
    $TotalAborted = $xmlData.testsuites.testsuite.properties.property | Where-Object { $_.name -eq "TotalAborted" } | Select-Object -ExpandProperty value
    
   if ($totalAssertsFailures -gt 0) {
        Write-Output "Error $Testname: There are failed assertions."
        exit -1
    }

    if ($skippedTestcases -gt 0) {
        Write-Output "Error $Testname: There are skipped test cases."
        exit -1
    }

    if ($totalAborted -gt 0) {
        Write-Output "Error $Testname: There are aborted tests."
        exit -1
    }

    if ($totalTestcases -ne $successfullTestcases) {
        Write-Output "Error $Testname: Not all test cases were successful."
        exit -1
    }

    if ($totalAsserts -ne $totalAssertsPassed) {
        Write-Output "Error $Testname: Not all assertions passed."
        exit -1
    }

    Write-Output "All of $Testname passed successfully!" 

}


checkResult -Testname "TEST_mt_ProcEng"
