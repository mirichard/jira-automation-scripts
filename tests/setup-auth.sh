#!/bin/bash

# Authentication Setup for Jira Testing
# This script sets up the required authentication for testing

echo "Setting up Jira authentication for testing..."

# Check if environment variables are already set
if [ -n "$JIRA_EMAIL" ] && [ -n "$JIRA_API_TOKEN" ]; then
    echo "✅ Jira credentials found in environment"
    export JIRA_AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_API_TOKEN" | base64)
    echo "✅ JIRA_AUTH encoded and exported"
else
    echo "❌ JIRA_EMAIL and JIRA_API_TOKEN environment variables not found"
    echo "Please set them before running tests:"
    echo "export JIRA_EMAIL='your-email@example.com'"
    echo "export JIRA_API_TOKEN='your-api-token'"
    exit 1
fi

# Test the authentication
echo "Testing Jira authentication..."
curl -s -H "Authorization: Basic $JIRA_AUTH" \
    "https://flow-foundry.atlassian.net/rest/api/3/myself" | jq -r '.displayName // "Authentication failed"'
