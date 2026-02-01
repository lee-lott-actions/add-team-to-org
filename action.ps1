function Add-GitHubTeamToOrg {
    param(
        [string]$TeamName,
        [string]$TeamDescription,
        [string]$Owner,
        [string]$Token
    )

    # Validate required parameters
    if ([string]::IsNullOrEmpty($TeamName) -or
        [string]::IsNullOrEmpty($TeamDescription) -or
        [string]::IsNullOrEmpty($Owner) -or
        [string]::IsNullOrEmpty($Token)) {
        Write-Host "Error: Missing required parameters"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided."
        return
    }

    Write-Host "Attempting to create team '$TeamName' in organization '$Owner' with description '$TeamDescription'."

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/orgs/$Owner/teams"

    $headers = @{
        Authorization        = "Bearer $Token"
        Accept               = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
        "User-Agent"         = "pwsh-action"
        "Content-Type"       = "application/json"
    }

    $jsonBody = @{
        name                 = $TeamName
        description          = $TeamDescription
        privacy              = "closed"
        notification_setting = "notifications_enabled"
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $jsonBody
        if ($response.StatusCode -eq 201) {
            Write-Host "Team '$TeamName' successfully created."
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
        } else {
			$errorMsg = "Error: Failed to add team $TeamName to organization $Owner. HTTP Status: $($response.StatusCode)"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
            Write-Host $errorMsg
        }
    } catch {
		$errorMsg = "Error: Failed to add team $TeamName to organization $Owner. Exception: $($_.Exception.Message)"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
    }
}