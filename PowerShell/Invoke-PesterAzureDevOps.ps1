Import-Module Pester

# Path to the directory containing your Pester tests
$testDirectory = "Script-Execution-Pipeline-Project/PowerShell/tests"

# Output file for Pester results
$outputFile = ".\TEST-RESULTS.xml"

# Run Pester tests
Invoke-Pester -Path $testDirectory -OutputFile $outputFile -OutputFormat NUnitXml