[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $sqlServerFQDN,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerAdminUserName,

    [Parameter(Mandatory = $true)]
    [string] $sqlDbName,

    [Parameter(Mandatory = $true)]
    [string] $ScriptFolder,

    [Parameter(Mandatory = $true)]
    [string] $ScriptName,

    [Parameter(Mandatory = $true)]
    [string] $instrumentationKey,

    [Parameter(Mandatory = $false)]
    [string] $queuedBy,

    [Parameter(Mandatory = $true)]
    [string] $Mode,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerName,

    [Parameter(Mandatory = $true)]
    [string] $keyVaultName
)
function errorHandling {
    param (
        $errorMessage
    )
    if ($? -eq $false) {
        throw $errorMessage
    }    
}
# Add function to retrieve keyvault secret
function getKeyVaultSecret {
    param(
        $secretName,
        $keyVaultName
    )
    Write-Host "Fetching key vault secret $secretName from key vault $keyVaultName..."
    $keyVaultSecret = az keyvault secret show -n $secretName --vault-name $keyVaultName --query "value" -o tsv
    errorHandling -errorMessage "Failed to get key vault secret $secretName from key vault $keyVaultName"
    return $keyVaultSecret
}

$sqlServerPassword = getKeyVaultSecret -secretName $sqlServerName -keyVaultName $keyVaultName

# Install the SqlServer module
Install-Module -Name SqlServer -Force

# Install the ApplicationInsightsCustomEvents module and define the LogAppInsight function only if the job mode is "commit"
if ($Mode -eq "commit" -and $instrumentationKey) {
    Install-Module ApplicationInsightsCustomEvents -Scope CurrentUser -Force -AllowClobber

    # Define the LogAppInsight function - this creates the customEvent which will be logged in App Insights
    function LogAppInsight ([string]$status, [string]$targetScript, [string]$targetDatabase, [string]$queuedBy, [string]$exceptionMessage, [string]$output) {
        $dictionary = New-Object 'System.Collections.Generic.Dictionary[string,string]' 
        $dictionary.Add('Status', "$status") | Out-Null
        $dictionary.Add('Target Script', "$targetScript") | Out-Null 
        $dictionary.Add('Target Database', "$targetDatabase") | Out-Null 
        $dictionary.Add('Queued By', "$queuedBy") | Out-Null
        $dictionary.Add('Exception Message', "$exceptionMessage") | Out-Null
        $dictionary.Add('Details', "$output") | Out-Null
        Log-ApplicationInsightsEvent -InstrumentationKey $instrumentationKey -EventName "SQL Script Execution" -EventDictionary $dictionary
    }
}

# Construct the SQL script path
$scriptPath = Join-Path -Path "./database-scripts/$ScriptFolder" -ChildPath $ScriptName

# Read the SQL script content
$sqlScript = Get-Content -Path $scriptPath -Raw

# If the job mode is rollback, replace "COMMIT TRANSACTION" with "ROLLBACK TRANSACTION"
if ($Mode -eq "rollback") {
    $sqlScript = $sqlScript -replace "COMMIT TRANSACTION", "ROLLBACK TRANSACTION"
    Write-Host $sqlScript
}

Write-Host "Executing SQL script: $ScriptName"
Write-Host "Target database: $sqlDbName"

try {
    # Attempt to execute the SQL script with verbose, and include the message in the standard output for error handling
    $output = Invoke-Sqlcmd -ServerInstance $sqlServerFQDN -Database $sqlDbName -Username $sqlServerAdminUserName -Password $sqlServerPassword -Query $sqlScript -OutputSqlErrors $true -IncludeSqlUserErrors -ErrorAction Stop -Verbose 4>&1

    Write-Host "SQL script executed successfully: $output"

    # Log success message to Application Insights
    if ($Mode -eq "commit" -and $instrumentationKey) {
        LogAppInsight "Success" "$ScriptName" "$sqlDbName" "$queuedBy" "" "$output"
        Write-Host "Logged success message to application insights."
    }
}
catch {
    Write-Host "[Error] $($_.Exception.Message)"
    Write-Host "##vso[task.complete result=Failed;]Failed" # Needed to force a pipeline failure
    
    # Log failure message to Application Insights
    if ($Mode -eq "commit" -and $instrumentationKey) {
        LogAppInsight "Failure" "$ScriptName" "$sqlDbName" "$queuedBy" "$($_.Exception.Message)"
        Write-Host "Logged failure message to application insights,"
    }
    exit 1
}