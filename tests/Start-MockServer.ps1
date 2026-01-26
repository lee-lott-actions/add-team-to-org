param(
    [int]$Port = 3000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host "Mock server listening on http://127.0.0.1:$Port..." -ForegroundColor Green

function GetJsonBody($request) {
    $reader = New-Object System.IO.StreamReader($request.InputStream)
    $body = $reader.ReadToEnd()
    $reader.Close()
    if ($body) {
        try { return $body | ConvertFrom-Json } catch { return $null }
    } else {
        return $null
    }
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath
        $method = $request.HttpMethod

        Write-Host "Mock intercepted: $method $path" -ForegroundColor Cyan

        $responseJson = $null
        $statusCode = 200

       # HealthCheck endpoint: GET /HealthCheck
        if ($method -eq "GET" -and $path -eq "/HealthCheck") {
            $statusCode = 200
            $responseJson = @{ status = "ok" } | ConvertTo-Json
        }
        # POST /orgs/:owner/teams
        elseif ($method -eq "POST" -and $path -match '^/orgs/([^/]+)/teams$') {
            $owner = $Matches[1]
            $bodyObj = GetJsonBody $request

            Write-Host "Request headers: $($request.Headers | Out-String)"
            Write-Host "Request body: $(if ($bodyObj) { $bodyObj | ConvertTo-Json -Compress } else { '[null]' })"

            $name                 = $bodyObj.name
            $description          = $bodyObj.description
            $privacy              = $bodyObj.privacy
            $notification_setting = $bodyObj.notification_setting

            if (-not $name -or -not $description -or -not $privacy -or -not $notification_setting) {
                $statusCode = 400
                $responseJson = @{ message = "Bad Request: Missing required fields in request body" } | ConvertTo-Json
            }
            elseif ($owner -eq "test-owner" -and $name -eq "test-team") {
                $statusCode = 201
                $responseJson = @{ id = 123; name = "test-team"; slug = "test-team"; description = $description } | ConvertTo-Json
            }
            elseif ($name -eq "existing-team") {
                $statusCode = 422
                $responseJson = @{ message = "Unprocessable Entity: Team already exists" } | ConvertTo-Json
            }
            else {
                $statusCode = 400
                $responseJson = @{ message = "Bad Request: Invalid team name or organization" } | ConvertTo-Json
            }
        }
        else {
            $statusCode = 404
            $responseJson = @{ message = "Not Found" } | ConvertTo-Json
        }

        # Send response
        $response.StatusCode = $statusCode
        $response.ContentType = "application/json"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Mock server stopped." -ForegroundColor Yellow
}