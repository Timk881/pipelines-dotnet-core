function checkResult {
    param(
        [string]$Testname
    )

    $FilePath = "C:\Users\tkohlert\Desktop\Testagent\_work\2\b\TestResults\$Testname.xml"
    [xml]$xmlData = Get-Content -Path $FilePath

    # Testcases: Retrieve all properties first
    $properties = $xmlData.testsuites.testsuite.properties.property

    # Extract and convert the property values to integers
    $totalTestcases = $properties | Where-Object { $_.name -eq "TotalTestcases" } | Select-Object -ExpandProperty value
    $successfulTestcases = $properties | Where-Object { $_.name -eq "SuccessfullTestcases" } | Select-Object -ExpandProperty value
    $skippedTestcases = $properties | Where-Object { $_.name -eq "SkippedTestcases" } | Select-Object -ExpandProperty value

    # Check if values were correctly retrieved
    Write-Output "Debugging TotalTestcases: '$totalTestcases'"
    Write-Output "Debugging SuccessfulTestcases: '$successfulTestcases'"

    # Handle null or empty successfulTestcases value
    if (-not $successfulTestcases) {
        Write-Output "Warning: SuccessfullTestcases not found or is empty."
    }

    # Convert the extracted values to integers, handling any potential whitespace or null
    $totalTestcases = [int]($totalTestcases.Trim())
    $successfulTestcases = if ($successfulTestcases) { [int]($successfulTestcases.Trim()) } else { 0 }

    # Now perform the checks
    if ($totalTestcases -ne $successfulTestcases) {
        Write-Output "Error ${Testname}: Not all test cases were successful."
        exit -1
    }

    # Further logic based on assertions and skipped test cases
    $totalAssertsfailures = $properties | Where-Object { $_.name -eq "TotalAssertsFailures" } | Select-Object -ExpandProperty value
    $totalAsserts = $properties | Where-Object { $_.name -eq "totalAsserts" } | Select-Object -ExpandProperty value
    $totalAssertspassed = $properties | Where-Object { $_.name -eq "TotalAssertsPassed" } | Select-Object -ExpandProperty value
    $totalAborted = $properties | Where-Object { $_.name -eq "TotalAborted" } | Select-Object -ExpandProperty value

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
