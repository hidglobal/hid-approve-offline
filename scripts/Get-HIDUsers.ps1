param (
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

function Get-AuthenticatorDetails {
    param (
        [string]$accessToken,
        [string]$authenticatorUrl
    )
    $response = Invoke-RestMethod -Uri $authenticatorUrl -Method Get -Headers @{
        Authorization = "Bearer $accessToken"
        'Content-Type' = 'application/scim+json'
    }
    return $response.statistics.lastSuccessfulDate
}

function Get-Users {
    param (
        [string]$accessToken,
        [string]$scimUrl
    )
    $csvPath = "users.csv"
    $csvHeader = "id,userName,lastLogon"
    $csvHeader | Out-File -FilePath $csvPath -Encoding utf8

    $userCount = 0
    $maxUsers = 100
    do {
        Write-Host "Getting users $userCount to $($userCount + 100)" -NoNewline
        $body = @{
            attributes = @('id', 'externalId', 'urn:hid:scim:api:idp:2.0:UserAuthenticator')
            filter = 'groups.value eq USG_FTEMP'
            sortBy = 'id'
            sortOrder = 'ascending'
            startIndex = $userCount
            count = 100
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$scimUrl/Users/.search" -Method Post -Headers @{
            Authorization = "Bearer $accessToken"
            'Content-Type' = 'application/scim+json'
        } -Body $body

        $maxUsers = $response.totalResults
        $userCount += $response.resources.Count

        foreach ($user in $response.resources) {
            $authenticatorRef = $user.'urn:hid:scim:api:idp:2.0:UserAuthenticator'.authenticators[0].'$ref'
            $lastLogon = if ($authenticatorRef) {
                Get-AuthenticatorDetails -accessToken $accessToken -authenticatorUrl $authenticatorRef
            } else {
                "N/A"
            }
            "$($user.id),$($user.externalId),$lastLogon" | Out-File -FilePath $csvPath -Append -Encoding utf8
        }
        Write-Host "`r" -NoNewline
    } while ($userCount -lt $maxUsers)

    Write-Output "Exported $userCount users to $csvPath"
}

$accessToken = Get-AccessToken -clientId $clientId -clientSecret $clientSecret -authUrl $authUrl
Get-Users -accessToken $accessToken -scimUrl $scimUrl
