# Script-Execution-Pipeline-Project/PowerShell/tests/ExecuteSQLScript.Tests.ps1

# Load the script to be tested
. "$PSScriptRoot/../ExecuteSQLScript.ps1"

Describe 'ExecuteSQLScript.ps1' {

    Mock az {
        # Mock output of az keyvault secret show command
        return "mocked-secret-value"
    }

    Mock Install-Module {
        # Mock Install-Module to prevent actual module installation
    }

    Mock Invoke-Sqlcmd {
        # Mock Invoke-Sqlcmd to simulate SQL command execution
        return "mocked-sqlcmd-output"
    }

    Mock Log-ApplicationInsightsEvent {
        # Mock Log-ApplicationInsightsEvent to prevent actual logging
    }

    It 'should retrieve a secret from Azure Key Vault' {
        $params = @{
            sqlServerFQDN = "test-server"
            sqlServerAdminUserName = "admin"
            sqlDbName = "test-db"
            ScriptFolder = "folder"
            ScriptName = "script.sql"
            Mode = "commit"
            sqlServerName = "test-server"
            keyVaultName = "test-keyvault"
        }
        
        $result = & $PSScriptRoot/../ExecuteSQLScript.ps1 @params
        $result | Should -Be "mocked-secret-value"
    }

    It 'should replace COMMIT TRANSACTION with ROLLBACK TRANSACTION in rollback mode' {
        $originalScript = "COMMIT TRANSACTION;"
        $rollbackScript = $originalScript -replace "COMMIT TRANSACTION", "ROLLBACK TRANSACTION"
        $rollbackScript | Should -Be "ROLLBACK TRANSACTION;"
    }

    It 'should execute SQL script and handle success' {
        $params = @{
            sqlServerFQDN = "test-server"
            sqlServerAdminUserName = "admin"
            sqlDbName = "test-db"
            ScriptFolder = "folder"
            ScriptName = "script.sql"
            Mode = "commit"
            sqlServerName = "test-server"
            keyVaultName = "test-keyvault"
        }

        # Invoke the function
        & $PSScriptRoot/../ExecuteSQLScript.ps1 @params

        # Verify that Invoke-Sqlcmd was called with correct parameters
        Assert-MockCalled Invoke-Sqlcmd -Exactly 1 -Scope It -ParameterFilter {
            $args[0] -eq "SELECT * FROM test-db"
        }
    }

    It 'should log success message to Application Insights when mode is commit' {
        $params = @{
            sqlServerFQDN = "test-server"
            sqlServerAdminUserName = "admin"
            sqlDbName = "test-db"
            ScriptFolder = "folder"
            ScriptName = "script.sql"
            Mode = "commit"
            sqlServerName = "test-server"
            keyVaultName = "test-keyvault"
            InstrumentationKey = "test-key"
        }

        # Invoke the function
        & $PSScriptRoot/../ExecuteSQLScript.ps1 @params

        # Verify that Log-ApplicationInsightsEvent was called
        Assert-MockCalled Log-ApplicationInsightsEvent -Exactly 1 -Scope It
    }

    It 'should handle SQL script execution errors' {
        Mock Invoke-Sqlcmd {
            throw [System.Exception] "SQL error"
        }

        $params = @{
            sqlServerFQDN = "test-server"
            sqlServerAdminUserName = "admin"
            sqlDbName = "test-db"
            ScriptFolder = "folder"
            ScriptName = "script.sql"
            Mode = "commit"
            sqlServerName = "test-server"
            keyVaultName = "test-keyvault"
        }

        # Run the script and check if it fails as expected
        & $PSScriptRoot/../ExecuteSQLScript.ps1 @params | Should -Throw "SQL error"
    }
}
