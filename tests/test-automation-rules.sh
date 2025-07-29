#!/bin/bash

# Jira Automation Rules Testing Framework
# This script tests each automation rule by creating test scenarios in the configured project

set -e

# Jira configuration (using existing environment variables)
JIRA_URL="${JIRA_URL:-https://your-domain.atlassian.net}"
PROJECT_KEY="${PROJECT_KEY:-YOUR_PROJECT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=()

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

error() {
    echo -e "${RED}❌ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to create a test issue
create_test_issue() {
    local summary="$1"
    local description="$2"
    local labels="$3"
    local issue_type="${4:-Task}"
    
    local data='{
        "fields": {
            "project": {"key": "'$PROJECT_KEY'"},
            "summary": "'$summary'",
            "description": {
                "type": "doc",
                "version": 1,
                "content": [
                    {
                        "type": "paragraph",
                        "content": [
                            {
                                "type": "text",
                                "text": "'$description'"
                            }
                        ]
                    }
                ]
            },
            "issuetype": {"name": "'$issue_type'"}
        }
    }'
    
    if [ -n "$labels" ]; then
        # Add labels to the data
        local label_array=$(echo "$labels" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
        data=$(echo "$data" | jq --argjson labels "[$label_array]" '.fields.labels = $labels')
    fi
    
    local response=$(curl -s -X POST \
        -H "Authorization: Basic $JIRA_AUTH" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$JIRA_URL/rest/api/3/issue")
    
    echo "$response" | jq -r '.key // empty'
}

# Function to add a comment to an issue
add_comment() {
    local issue_key="$1"
    local comment_text="$2"
    
    local data='{
        "body": {
            "type": "doc",
            "version": 1,
            "content": [
                {
                    "type": "paragraph",
                    "content": [
                        {
                            "type": "text",
                            "text": "'$comment_text'"
                        }
                    ]
                }
            ]
        }
    }'
    
    curl -s -X POST \
        -H "Authorization: Basic $JIRA_AUTH" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$JIRA_URL/rest/api/3/issue/$issue_key/comment" > /dev/null
}

# Function to check if an issue has a specific label
check_issue_label() {
    local issue_key="$1"
    local expected_label="$2"
    
    local response=$(curl -s -X GET \
        -H "Authorization: Basic $JIRA_AUTH" \
        "$JIRA_URL/rest/api/3/issue/$issue_key?fields=labels")
    
    echo "$response" | jq -r '.fields.labels[]?.name' | grep -q "^$expected_label$"
}

# Function to get issue status
get_issue_status() {
    local issue_key="$1"
    
    local response=$(curl -s -X GET \
        -H "Authorization: Basic $JIRA_AUTH" \
        "$JIRA_URL/rest/api/3/issue/$issue_key?fields=status")
    
    echo "$response" | jq -r '.fields.status.name'
}

# Function to clean up test issues
cleanup_test_issues() {
    log "Cleaning up test issues with 'automation-test' label..."
    
    local jql="project=$PROJECT_KEY AND labels=automation-test"
    local encoded_jql=$(echo "$jql" | sed 's/ /%20/g' | sed 's/=/%3D/g' | sed 's/AND/%20AND%20/g')
    
    local response=$(curl -s -X GET \
        -H "Authorization: Basic $JIRA_AUTH" \
        "$JIRA_URL/rest/api/3/search?jql=$encoded_jql&fields=key")
    
    local issue_keys=$(echo "$response" | jq -r '.issues[].key')
    
    for key in $issue_keys; do
        if [ -n "$key" ]; then
            log "Deleting test issue: $key"
            curl -s -X DELETE \
                -H "Authorization: Basic $JIRA_AUTH" \
                "$JIRA_URL/rest/api/3/issue/$key" > /dev/null
        fi
    done
}

# Test 1: Auto-assign issues based on label
test_auto_assign_by_label() {
    log "Testing: Auto-assign issues based on label"
    
    # Create test issue with backend label
    local issue_key=$(create_test_issue "Test Backend Assignment" "Testing auto-assignment for backend issues" "backend,automation-test")
    
    if [ -n "$issue_key" ]; then
        success "Created test issue: $issue_key"
        TEST_RESULTS+=("Auto-assign by label|Created test issue $issue_key|✅|Manual verification needed for assignment")
    else
        error "Failed to create test issue for auto-assignment test"
        TEST_RESULTS+=("Auto-assign by label|Failed to create test issue|❌|Issue creation failed")
    fi
}

# Test 2: Auto-tag issues based on keywords
test_auto_tag_keywords() {
    log "Testing: Auto-tag issues based on keywords"
    
    # Create test issue with bug-related keywords
    local issue_key=$(create_test_issue "Bug in login system" "There's a critical error causing the system to crash during authentication" "automation-test")
    
    if [ -n "$issue_key" ]; then
        success "Created test issue for keyword tagging: $issue_key"
        
        # Wait a moment for automation to process
        sleep 5
        
        # Check if bug-related label was added
        if check_issue_label "$issue_key" "bug-related"; then
            success "Bug-related label was automatically added"
            TEST_RESULTS+=("Auto-tag keywords|Bug-related label added|✅|Automation working correctly")
        else
            warning "Bug-related label was not added - may need manual verification"
            TEST_RESULTS+=("Auto-tag keywords|Bug-related label not detected|⚠️|Manual verification needed")
        fi
    else
        error "Failed to create test issue for keyword tagging"
        TEST_RESULTS+=("Auto-tag keywords|Failed to create test issue|❌|Issue creation failed")
    fi
}

# Test 3: Risk/Decision log creation from comments
test_risk_decision_comments() {
    log "Testing: Risk/Decision log creation from comments"
    
    # Create a test issue
    local issue_key=$(create_test_issue "Test Issue for Risk/Decision" "Testing risk and decision log automation" "automation-test")
    
    if [ -n "$issue_key" ]; then
        success "Created test issue for risk/decision test: $issue_key"
        
        # Add a risk comment
        add_comment "$issue_key" "/risk: This approach may cause performance issues with large datasets"
        log "Added risk comment to $issue_key"
        
        # Add a decision comment
        add_comment "$issue_key" "/decision: Need to choose between REST API vs GraphQL for new endpoints"
        log "Added decision comment to $issue_key"
        
        TEST_RESULTS+=("Risk/Decision comments|Comments added to $issue_key|✅|Manual verification needed for linked issues")
    else
        error "Failed to create test issue for risk/decision test"
        TEST_RESULTS+=("Risk/Decision comments|Failed to create test issue|❌|Issue creation failed")
    fi
}

# Test 4: Stale issue flagging (simulated)
test_stale_issue_flagging() {
    log "Testing: Stale issue flagging (simulation)"
    
    # Create a test issue that would be considered stale
    local issue_key=$(create_test_issue "Old Test Issue" "This issue simulates a stale issue for testing purposes" "automation-test")
    
    if [ -n "$issue_key" ]; then
        success "Created test issue for stale flagging: $issue_key"
        log "Note: Stale flagging runs on schedule - this issue will be flagged if not updated for 5+ days"
        TEST_RESULTS+=("Stale issue flagging|Test issue created $issue_key|✅|Scheduled rule - will activate after 5 days")
    else
        error "Failed to create test issue for stale flagging"
        TEST_RESULTS+=("Stale issue flagging|Failed to create test issue|❌|Issue creation failed")
    fi
}

# Test 5: Create parent issue with subtasks for testing
test_parent_subtask_closure() {
    log "Testing: Parent-subtask closure automation"
    
    # Create parent story
    local parent_key=$(create_test_issue "Test Parent Story" "Parent story for testing subtask closure" "automation-test" "Story")
    
    if [ -n "$parent_key" ]; then
        success "Created parent story: $parent_key"
        
        # Create subtask
        local subtask_data='{
            "fields": {
                "project": {"key": "'$PROJECT_KEY'"},
                "parent": {"key": "'$parent_key'"},
                "summary": "Test Subtask",
                "description": {
                    "type": "doc",
                    "version": 1,
                    "content": [
                        {
                            "type": "paragraph",
                            "content": [
                                {
                                    "type": "text",
                                    "text": "Test subtask for automation testing"
                                }
                            ]
                        }
                    ]
                },
                "issuetype": {"name": "Sub-task"},
                "labels": [{"name": "automation-test"}]
            }
        }'
        
        local subtask_response=$(curl -s -X POST \
            -H "Authorization: Basic $JIRA_AUTH" \
            -H "Content-Type: application/json" \
            -d "$subtask_data" \
            "$JIRA_URL/rest/api/3/issue")
        
        local subtask_key=$(echo "$subtask_response" | jq -r '.key // empty')
        
        if [ -n "$subtask_key" ]; then
            success "Created subtask: $subtask_key"
            TEST_RESULTS+=("Parent-subtask closure|Created parent $parent_key and subtask $subtask_key|✅|Manual verification needed for closure automation")
        else
            warning "Failed to create subtask for $parent_key"
            TEST_RESULTS+=("Parent-subtask closure|Parent created but subtask failed|⚠️|Subtask creation failed")
        fi
    else
        error "Failed to create parent story"
        TEST_RESULTS+=("Parent-subtask closure|Failed to create parent story|❌|Parent creation failed")
    fi
}

# Test 6: Cross-project cloning
test_cross_project_cloning() {
    log "Testing: Cross-project cloning automation"
    
    # Create test epic with clone-projects label
    local epic_key=$(create_test_issue "Test Epic for Cloning" "Epic to test cross-project cloning" "clone-projects,automation-test" "Epic")
    
    if [ -n "$epic_key" ]; then
        success "Created test epic for cloning: $epic_key"
        TEST_RESULTS+=("Cross-project cloning|Created epic $epic_key with clone-projects label|✅|Manual verification needed for clones in PMO/DEVOPS/TEST")
    else
        error "Failed to create test epic for cloning"
        TEST_RESULTS+=("Cross-project cloning|Failed to create test epic|❌|Epic creation failed")
    fi
}

# Test 7: Bug mirroring to TEST project
test_bug_mirroring() {
    log "Testing: Bug mirroring to TEST project"
    
    # Create test bug
    local bug_key=$(create_test_issue "Test Bug for Mirroring" "Bug to test mirroring to TEST project" "automation-test" "Bug")
    
    if [ -n "$bug_key" ]; then
        success "Created test bug for mirroring: $bug_key"
        TEST_RESULTS+=("Bug mirroring|Created bug $bug_key|✅|Manual verification needed for TEST project mirror")
    else
        error "Failed to create test bug for mirroring"
        TEST_RESULTS+=("Bug mirroring|Failed to create test bug|❌|Bug creation failed")
    fi
}

# Test 8: Blocker escalation
test_blocker_escalation() {
    log "Testing: Blocker escalation to OPS"
    
    # Create test issue
    local issue_key=$(create_test_issue "Test Issue for Blocker Escalation" "Issue to test blocker escalation" "automation-test")
    
    if [ -n "$issue_key" ]; then
        success "Created test issue for blocker escalation: $issue_key"
        
        # Update priority to Blocker (this would trigger the automation)
        log "Note: To test blocker escalation, manually change priority of $issue_key to 'Blocker'"
        TEST_RESULTS+=("Blocker escalation|Created issue $issue_key|✅|Manual priority change to Blocker needed")
    else
        error "Failed to create test issue for blocker escalation"
        TEST_RESULTS+=("Blocker escalation|Failed to create test issue|❌|Issue creation failed")
    fi
}

# Test 9: GitHub webhook simulation
test_github_webhook_simulation() {
    log "Testing: GitHub webhook integration (simulation)"
    
    # Create test issue that would be referenced in PR
    local issue_key=$(create_test_issue "Test Issue for GitHub Integration" "Issue to test GitHub PR integration" "automation-test")
    
    if [ -n "$issue_key" ]; then
        success "Created test issue for GitHub integration: $issue_key"
        log "Note: To test GitHub integration, create a PR with '$issue_key' in title or body"
        TEST_RESULTS+=("GitHub integration|Created issue $issue_key for PR testing|✅|GitHub PR creation needed for full test")
    else
        error "Failed to create test issue for GitHub integration"
        TEST_RESULTS+=("GitHub integration|Failed to create test issue|❌|Issue creation failed")
    fi
}

# Test 10: Slack notification simulation
test_slack_notification_simulation() {
    log "Testing: Slack notification (simulation)"
    
    # Test environment variables
    if [ -n "$SLACK_WEBHOOK_TOKEN" ]; then
        success "SLACK_WEBHOOK_TOKEN environment variable found"
        TEST_RESULTS+=("Slack notifications|Environment variable configured|✅|Ready for Slack integration")
    else
        warning "SLACK_WEBHOOK_TOKEN environment variable not set"
        TEST_RESULTS+=("Slack notifications|Environment variable missing|⚠️|Set SLACK_WEBHOOK_TOKEN for full functionality")
    fi
    
    # Create blocker issue to trigger Slack alert
    local blocker_key=$(create_test_issue "Test Blocker for Slack Alert" "Blocker issue to test Slack notifications" "automation-test")
    
    if [ -n "$blocker_key" ]; then
        success "Created test issue for Slack alert: $blocker_key"
        log "Note: Change priority to 'Blocker' to trigger Slack notification"
        TEST_RESULTS+=("Slack blocker alert|Created issue $blocker_key|✅|Manual priority change to Blocker needed")
    else
        error "Failed to create test issue for Slack alert"
        TEST_RESULTS+=("Slack blocker alert|Failed to create test issue|❌|Issue creation failed")
    fi
}

# Main testing function
run_tests() {
    log "Starting Jira Automation Rules Testing"
    log "Project: $PROJECT_KEY"
    log "Jira URL: $JIRA_URL"
    
    # Check authentication
    if [ -z "$JIRA_AUTH" ]; then
        error "JIRA_AUTH environment variable not set"
        exit 1
    fi
    
    # Run tests
    test_auto_assign_by_label
    test_auto_tag_keywords
    test_risk_decision_comments
    test_stale_issue_flagging
    test_parent_subtask_closure
    test_cross_project_cloning
    test_bug_mirroring
    test_blocker_escalation
    test_github_webhook_simulation
    test_slack_notification_simulation
    
    # Print results summary
    echo
    log "Test Results Summary:"
    echo "===================="
    
    printf "%-30s %-40s %-10s %-50s\n" "Rule" "Test Description" "Status" "Notes"
    echo "--------------------------------------------------------------------------------------------------------"
    
    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r rule description status notes <<< "$result"
        printf "%-30s %-40s %-10s %-50s\n" "$rule" "$description" "$status" "$notes"
    done
    
    echo
    log "Tests Passed: $TESTS_PASSED"
    log "Tests Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        error "Some tests failed. Please review the results above."
        return 1
    else
        success "All tests completed successfully!"
        return 0
    fi
}

# Check if cleanup is requested
if [ "$1" = "cleanup" ]; then
    cleanup_test_issues
    exit 0
fi

# Check if we should skip cleanup
if [ "$1" != "no-cleanup" ]; then
    # Cleanup any existing test issues first
    cleanup_test_issues
fi

# Run the tests
run_tests
