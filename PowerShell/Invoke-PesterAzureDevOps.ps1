Import-Module Pester

# Output file for Pester results
$outputFile = ".\TEST-RESULTS.xml"

# Run Pester tests with external data
Invoke-Pester -Path $testDirectory -OutputFile $outputFile -OutputFormat NUnitXml
