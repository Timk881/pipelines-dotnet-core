function checkResult {
    param(
        [string]$Testname
    )

    $FilePath = "C:\Users\tkohlert\Desktop\Testagent\_work\2\b\TestResults\$Testname.xml"
    [xml]$xmlData = Get-Content -Path $FilePath
    $properties = $xmlData.testsuites.testsuite.properties.property


    # Extract Values
    $totalTestcases = $properties | Where-Object { $_.name -eq "TotalTestcases" } | Select-Object -ExpandProperty value
    $successfulTestcases = $properties | Where-Object { $_.name -eq "SuccessfullTestcases" } | Select-Object -ExpandProperty value
    $skippedTestcases = $properties | Where-Object { $_.name -eq "SkippedTestcases" } | Select-Object -ExpandProperty value
    $totalAssertsfailures = $properties | Where-Object { $_.name -eq "TotalAssertsFailures" } | Select-Object -ExpandProperty value
    $totalAsserts = $properties | Where-Object { $_.name -eq "totalAsserts" } | Select-Object -ExpandProperty value
    $totalAssertspassed = $properties | Where-Object { $_.name -eq "TotalAssertsPassed" } | Select-Object -ExpandProperty value
    $totalAborted = $properties | Where-Object { $_.name -eq "TotalAborted" } | Select-Object -ExpandProperty value

    
   # Evaluate Results
   
    if ($totalTestcases -ne $successfulTestcases) {
        Write-Output "Error ${Testname}: Not all test cases were successful."
        exit -1
    }
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

    if ($totalAsserts -ne $totalAssertspassed) {
        Write-Output "Error ${Testname}: Not all assertions passed."
        exit -1
    }

    Write-Output "All of ${Testname} passed successfully!" 
}

checkResult -Testname "TEST_mt_ProcEng"
