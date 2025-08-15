#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="dr-primary"
REGION="ca-central-1"
PROFILE=""  # e.g., set to '--profile myprofile' if you use a named profile, else leave empty

# Customize parameters here if desired
aws cloudformation deploy   --stack-name "${STACK_NAME}"   --template-file cloudformation/network-app.yml   --region "${REGION}"   ${PROFILE}   --capabilities CAPABILITY_NAMED_IAM   --parameter-overrides       EnvironmentName=prod       KeyName=""       SSHLocation="0.0.0.0/0"       DesiredCapacity=1       MinSize=1       MaxSize=1

echo "Deployment initiated. Check stack status:"
echo "aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${REGION} ${PROFILE} --query 'Stacks[0].StackStatus' --output text"
