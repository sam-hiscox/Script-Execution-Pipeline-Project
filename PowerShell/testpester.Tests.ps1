# KeyVaultFunctions.Tests.ps1

# Import Pester module
Import-Module Pester

# Import the functions to be tested
. "$PSScriptRoot\testpester.ps1"

# Pester test for getKeyVaultSecret
Describe "getKeyVaultSecret" {
    BeforeAll {
        # Mock the az command to return a predefined value
        Mock -CommandName az -MockWith {
            param (
                [string]$CommandName,
                [string[]]$Arguments
            )
            if ($Arguments -contains "show") {
                return "mock-secret-value"
            }
        }

        # Mock the errorHandling function to verify its call
        Mock -CommandName errorHandling -MockWith {
            param (
                [string]$errorMessage
            )
            Write-Host $errorMessage
        }
    }

    Context "when called with valid parameters" {
        It "should fetch the secret from the key vault" {
            $secretName = "testSecret"
            $keyVaultName = "testKeyVault"
            
            # Call the function
            $result = getKeyVaultSecret -secretName $secretName -keyVaultName $keyVaultName
            
            # Validate the result
            $result | Should -Be "mock-secret-value"
        }
    }
}
