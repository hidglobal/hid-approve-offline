param (
    [Parameter(Mandatory=$true)]
    [string]$csvPath,
    [string]$authUrl = "https://appliance_fqdn/idp/ENTERPRISE/authn",
    [string]$scimUrl = "https://appliance_fqdn/scim/ENTERPRISE/v2",
    [string]$clientId = "xxxx",
    [string]$clientSecret = "xxxx"
)

function Get-AccessToken {
    param (
        [string]$clientId,
        [string]$clientSecret,
        [string]$authUrl
    )
    $authBasic = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${clientId}:${clientSecret}"))
    $response = Invoke-RestMethod -Uri "$authUrl/token" -Method Post -Headers @{
        Authorization = "Basic $authBasic"
        'Content-Type' = 'application/x-www-form-urlencoded'
    } -Body 'grant_type=client_credentials'
    return $response.access_token
}

function Remove-Users {
    param (
        [string]$accessToken,
        [string]$scimUrl,
        [string]$csvPath
    )

    if (-not (Test-Path $csvPath)) {
        Write-Error "CSV file not found: $csvPath"
        return
    }

    $users = Import-Csv $csvPath
    $totalUsers = $users.Count
    $deleted = 0
    $failed = 0

    Write-Host "Starting deletion of $totalUsers users..."

    foreach ($user in $users) {
        $userId = $user.id
        try {
            Write-Host "Deleting user $userId..." -NoNewline
            Invoke-RestMethod -Uri "$scimUrl/Users/$userId" -Method Delete -Headers @{
                Authorization = "Bearer $accessToken"
            }
            Write-Host "Success" -ForegroundColor Green
            $deleted++
        }
        catch {
            Write-Host "Failed" -ForegroundColor Red
            Write-Host "Error deleting user ${userId}: $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }

    Write-Host "`nDeletion complete:"
    Write-Host "Total processed: $totalUsers"
    Write-Host "Successfully deleted: $deleted"
    Write-Host "Failed: $failed"
}

try {
    $accessToken = Get-AccessToken -clientId $clientId -clientSecret $clientSecret -authUrl $authUrl
    Remove-Users -accessToken $accessToken -scimUrl $scimUrl -csvPath $csvPath
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
}
