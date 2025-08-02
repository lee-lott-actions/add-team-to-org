#!/usr/bin/env bats

# Load the Bash script
load ../action.sh

# Mock the curl command to simulate API responses
mock_curl() {
  local http_code=$1
  local response_file=$2
  echo "$http_code"
  cat "$response_file" > response.json
}

# Setup function to run before each test
setup() {
  export GITHUB_OUTPUT=$(mktemp)
}

# Teardown function to clean up after each test
teardown() {
  rm -f response.json "$GITHUB_OUTPUT" mock_response.json
}

@test "add_team_to_org succeeds with HTTP 201" {
  echo '{"id": 123, "name": "test-team"}' > mock_response.json
  curl() { mock_curl "201" mock_response.json; }
  export -f curl

  run add_team_to_org "test-team" "Test Team Description" "test-owner" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=success" ]
}

@test "add_team_to_org fails with HTTP 400 (bad request)" {
  echo '{"message": "Bad Request"}' > mock_response.json
  curl() { mock_curl "400" mock_response.json; }
  export -f curl

  run add_team_to_org "test-team" "Test Team Description" "test-owner" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Failed to add team 'test-team' to organization 'test-owner' (HTTP Status: 400)" ]
}

@test "add_team_to_org fails with empty team_name" {
  run add_team_to_org "" "Test Team Description" "test-owner" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided." ]
}

@test "add_team_to_org fails with empty team_description" {
  run add_team_to_org "test-team" "" "test-owner" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided." ]
}

@test "add_team_to_org fails with empty owner" {
  run add_team_to_org "test-team" "Test Team Description" "" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided." ]
}

@test "add_team_to_org fails with empty token" {
  run add_team_to_org "test-team" "Test Team Description" "test-owner" ""

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: team-name, team-description, token, and owner must be provided." ]
}
