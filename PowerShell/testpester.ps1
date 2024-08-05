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

function errorHandling {
    param(
        $errorMessage
    )
    Write-Host $errorMessage
}
