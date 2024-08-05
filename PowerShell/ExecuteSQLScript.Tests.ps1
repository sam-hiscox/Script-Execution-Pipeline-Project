BeforeAll {
    . $PSScriptRoot/ExecuteSQLScript.ps1
}
Describe 'errorHandling' {
    It 'should throw an error when the previous command fails' {
        # Simulate a failed command
        $false | Should -Be $false

        # Test the errorHandling function
        { errorHandling -errorMessage "Test error message" } | Should -Throw "Test error message"
    }
}
