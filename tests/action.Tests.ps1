Describe "Add-GitHubTeamToOrg" {
    BeforeAll {
        $script:TeamName        = "test-team"
        $script:TeamDescription = "Test Team Description"
        $script:Owner           = "test-owner"
        $script:Token           = "fake-token"
        $script:MockApiUrl      = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }
    BeforeEach {
        $env:GITHUB_OUTPUT = "$PSScriptRoot/github_output.temp"
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        $env:MOCK_API = $script:MockApiUrl
    }
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Variable -Name MOCK_API -Scope Global -ErrorAction SilentlyContinue
    }

    It "add_team_to_org succeeds with HTTP 201" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 201; Content = '{"id": 123, "name": "test-team"}' }
        }
        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription $TeamDescription -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=success"
    }

    It "add_team_to_org fails with HTTP 400 (bad request)" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 400; Content = '{"message": "Bad Request"}' }
        }
        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription $TeamDescription -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Error: Failed to add team $TeamName to organization $Owner. HTTP Status: 400"
    }

    It "add_team_to_org fails with empty team_name" {
        Add-GitHubTeamToOrg -TeamName "" -TeamDescription $TeamDescription -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided."
    }

    It "add_team_to_org fails with empty team_description" {
        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription "" -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided."
    }

    It "add_team_to_org fails with empty owner" {
        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription $TeamDescription -Owner "" -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided."
    }

    It "add_team_to_org fails with empty token" {
        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription $TeamDescription -Owner $Owner -Token ""
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided."
    }
	
	It "writes result=failure and error-message on exception" {
		Mock Invoke-WebRequest { throw "API Error" }

		try {
			Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription $TeamDescription -Owner $Owner -Token $Token
		} catch {}

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Where-Object { $_ -match "^error-message=Error: Failed to add team $TeamName to organization $Owner\. Exception:" } |
			Should -Not -BeNullOrEmpty
	}	
}