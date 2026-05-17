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
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
	    It "unit: Add-GitHubTeamToOrg succeeds with HTTP 201" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 201; Content = '{"id": 123, "name": "test-team"}' }
	        }
	        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription $TeamDescription -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=success"
	    }	
	}

	Context "HTTP Failure Cases" {
	    It "unit: Add-GitHubTeamToOrg fails with HTTP 400" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 400; Content = '{"message": "Bad Request"}' }
	        }
	        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription $TeamDescription -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Error: Failed to add team $TeamName to organization $Owner. HTTP Status: 400"
	    }
	}
	
	Context "Parameter Validation Failure Cases" {
	    It "unit: Add-GitHubTeamToOrg fails with empty TeamName" {
	        Add-GitHubTeamToOrg -TeamName "" -TeamDescription $TeamDescription -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided."
	    }
	
	    It "unit: Add-GitHubTeamToOrg fails with empty TeamDescription" {
	        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription "" -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided."
	    }
	
	    It "unit: Add-GitHubTeamToOrg fails with empty Owner" {
	        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription $TeamDescription -Owner "" -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided."
	    }
	
	    It "unit: Add-GitHubTeamToOrg fails with empty Token" {
	        Add-GitHubTeamToOrg -TeamName $TeamName -TeamDescription $TeamDescription -Owner $Owner -Token ""
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided."
	    }	
	}

	Context "Exception Failure Cases" {
		It "unit: Add-GitHubTeamToOrg fails with exception" {
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
}
