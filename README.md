# Jira Utilities Scripts

This directory contains utility scripts for managing Jira tickets and automating common tasks.

## Available Scripts

### 1. `bulk-delete-jira-alerts.sh`
Deletes Jira tickets with alert-type titles containing "Workflow Health Alert:" or "CRITICAL ALERT:"
- **Usage:** `./bulk-delete-jira-alerts.sh`
- **Setup:** See `JIRA_BULK_DELETE_SETUP.md`
- **Features:** Dry run mode, confirmation prompts, rate limiting

### 2. `bulk-delete-jira-range.sh`
Deletes a range of Jira tickets by ticket number (e.g., SCRUM-90 to SCRUM-196)
- **Usage:** `./bulk-delete-jira-range.sh`
- **Setup:** See `JIRA_BULK_DELETE_RANGE_SETUP.md`
- **Features:** Range validation, dry run mode, progress tracking

### 3. `bulk-update-jira-status.sh`
Updates ticket status in bulk (e.g., from "In Progress" to "Backlog")
- **Usage:** `./bulk-update-jira-status.sh`
- **Features:** Transition ID detection, batch processing, error handling

### 4. `clean-jira-descriptions.sh`
Cleans up ticket descriptions by removing stray escape characters (\\n, \\", etc.)
- **Usage:** `./clean-jira-descriptions.sh`
- **Features:** ADF format compatibility, text cleanup, batch processing

## Environment Setup

All scripts require these environment variables:
```bash
export JIRA_EMAIL='your-email@domain.com'
export JIRA_API_TOKEN='your-api-token'
```

## Jira Configuration

- **Jira URL:** https://flow-foundry.atlassian.net
- **Project Key:** SCRUM
- **API Version:** v3 (REST API)

## Security Notes

- Never commit API tokens to version control
- Store credentials securely as environment variables
- Use rate limiting to avoid API throttling
- Always test with dry run mode first

## Usage Examples

```bash
# Set up environment
export JIRA_EMAIL='michael@example.com'
export JIRA_API_TOKEN='your-token-here'

# Clean ticket descriptions
./clean-jira-descriptions.sh

# Update ticket status
./bulk-update-jira-status.sh

# Delete alert tickets (with dry run first)
./bulk-delete-jira-alerts.sh

# Delete ticket range
./bulk-delete-jira-range.sh
```

---
*Created: 2025-07-29*
*Location: ~/scripts/jira-utilities/*
