# KeyVaultFunctions.Tests.ps1

# Import Pester module
Import-Module Pester

# Import the functions to be tested
. "$PSScriptRoot\ExecuteSQLScript.ps1"

# Pester test for getKeyVaultSecret
Describe "getKeyVaultSecret" {
    BeforeAll {
        # Mock the az command to return a predefined value for a specific secret show request
        Mock -CommandName az -MockWith {
            param ([string[]]$Arguments)
            if ($Arguments -contains "show") {
                return "mock-secret-value"
            }
        }

        # Mock the errorHandling function to verify it is called only when an error occurs
        Mock -CommandName errorHandling
    }

    It "should call errorHandling when az command fails" {
        # Modify the az mock to return $null to simulate failure
        Mock -CommandName az -MockWith { return $null }

        $secretName = "testSecret"
        $keyVaultName = "testKeyVault"
        
        # Call the function
        $result = getKeyVaultSecret -secretName $secretName -keyVaultName $keyVaultName
        
        # Validate that the result is $null
        $result | Should -Be $null
        
        # Ensure errorHandling was called
        Assert-MockCalled -CommandName errorHandling -Times 1
    }
}
