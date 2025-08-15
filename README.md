# Add Team to Organization Action

This GitHub Action creates a new team in a specified GitHub organization with a given name and description using the GitHub API. It returns the result of the operation (`success` or `failure`) and an error message if the operation fails.

## Features
- Creates a team in an organization via a POST request to the GitHub API.
- Expects a slugified team name for API compatibility.
- Requires a team description and defaults to closed privacy with notifications enabled.
- Outputs the result of the operation (`result`) and an error message.
- Requires a GitHub token with organization admin permissions.
- Includes debug logging to ensure step output visibility in the GitHub Actions UI.
- Validates required inputs and permissions for reliability.

## Inputs
| Name              | Description                                              | Required | Default |
|-------------------|----------------------------------------------------------|----------|---------|
| `team-name`       | The slugified name of the team to create (e.g., "code-approvers"). | Yes      | N/A     |
| `team-description`| Description of the team.                                 | Yes      | N/A     |
| `owner`           | The owner of the organization (user or organization).    | Yes      | N/A     |
| `token`           | GitHub token with `admin:org` permissions.               | Yes      | N/A     |

## Outputs
| Name           | Description                                              |
|----------------|----------------------------------------------------------|
| `result`       | Result of the team creation operation (`success` or `failure`). |
| `error-message`| Error message if the team creation operation fails.      |

## Usage
1. **Add the Action to Your Workflow**:
   Create or update a workflow file (e.g., `.github/workflows/add-team-to-org.yml`) in your repository.

2. **Reference the Action**:
   Use the action by referencing the repository and version (e.g., `v1`).

3. **Example Workflow**:
   ```yaml
   name: Add Team to Organization
   on:
     workflow_dispatch:
       inputs:
         team-name:
           description: 'Slugified name of the team to create (e.g., "code-approvers")'
           required: true
         team-description:
           description: 'Description of the team'
           required: true
     issue_comment:
       types: [created]
   jobs:
     add-team:
       runs-on: ubuntu-latest
       steps:
         - name: Parse Issue Form
           id: parse
           if: github.event_name == 'issue_comment'
           run: |
             echo 'json={"team-name":"${{ github.event.comment.body }}","team-description":"Team created via issue comment"}' >> $GITHUB_OUTPUT
         - name: Add Team to Organization
           id: add-team
           uses: lee-lott-actions/add-team-to-org@v1
           with:
             team-name: 'team-name'
             team-description: 'team-description'
             owner: ${{ github.repository_owner }}
             token: ${{ secrets.GITHUB_TOKEN }}       
         - name: Print Result
           run: |
             if [[ "${{ steps.add-team.outputs.result }}" == "success" ]]; then
               echo "Successfully created team ${{ github.event.inputs.team-name || fromJson(steps.parse.outputs.json)['team-name'] }}."
             else
               echo "Error: ${{ steps.add-team.outputs.error-message }}"
               exit 1
             fi
