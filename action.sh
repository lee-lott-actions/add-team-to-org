#!/bin/bash

add_team_to_org() {
  local team_name="$1"
  local team_description="$2"  
  local owner="$3"
  local token="$4"
  
  if [ -z "$team_name" ] || [ -z "$team_description" ] || [ -z "$token" ] || [ -z "$owner" ]; then
    echo "Error: Missing required parameters"
    echo "result=failure" >> "$GITHUB_OUTPUT"
    echo "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided." >> $GITHUB_OUTPUT
    return
  fi

  echo "Attempting to create team '$team_name' in organization '$owner' with description '$team_description'."

  # Use MOCK_API if set, otherwise default to GitHub API
  local api_base_url="${MOCK_API:-https://api.github.com}"

  # Make API request to create the team
  RESPONSE=$(curl -s -o response.json -w "%{http_code}" -X POST \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Content-Type: application/json" \
    "$api_base_url/orgs/$owner/teams" \
    -d "{\"name\":\"$team_name\",\"description\":\"$team_description\",\"privacy\":\"closed\",\"notification_setting\":\"notifications_enabled\"}") 

  # Check if the request was successful (HTTP 201 for team creation)
  if [ "$RESPONSE" -eq 201 ]; then
    echo "Team '$team_name' successfully created."
    echo "result=success" >> "$GITHUB_OUTPUT"
  else
    echo "Error: Failed to add team '$team_name' to organization '$owner' (HTTP Status: $RESPONSE)"
    echo "result=failure" >> "$GITHUB_OUTPUT"
    echo "error-message=Failed to add team '$team_name' to organization '$owner' (HTTP Status: $RESPONSE)" >> "$GITHUB_OUTPUT"
  fi

  # Clean up temporary file
  rm -f response.json
}
