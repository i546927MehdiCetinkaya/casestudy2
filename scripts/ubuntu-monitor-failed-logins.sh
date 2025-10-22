#!/bin/bash
# Ubuntu Failed Login Monitor voor AWS Lambda SOAR
# Dit script monitort /var/log/auth.log en stuurt failed login events naar EventBridge

# AWS Configuration
AWS_REGION="eu-central-1"
EVENT_BUS="default"
EVENT_SOURCE="custom.security"
EVENT_DETAIL_TYPE="Failed Login Attempt"
ROLE_ARN="REPLACE_WITH_ROLE_ARN"  # Wordt ingevuld na terraform apply

# Log file to monitor
LOG_FILE="/var/log/auth.log"
