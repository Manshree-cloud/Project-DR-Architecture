#!/usr/bin/env bash
set -e
PRIMARY_REGION="ca-central-1"
SECONDARY_REGION="us-east-1"

ASG_PRIMARY=$(aws cloudformation describe-stacks --region $PRIMARY_REGION \
  --stack-name dr-cmp-primary \
  --query "Stacks[0].Outputs[?OutputKey=='AsgName'].OutputValue" --output text)

ASG_SECONDARY=$(aws cloudformation describe-stacks --region $SECONDARY_REGION \
  --stack-name dr-cmp-secondary \
  --query "Stacks[0].Outputs[?OutputKey=='AsgName'].OutputValue" --output text)

aws autoscaling update-auto-scaling-group \
  --region $PRIMARY_REGION \
  --auto-scaling-group-name "$ASG_PRIMARY" \
  --min-size 0 --desired-capacity 0

aws autoscaling update-auto-scaling-group \
  --region $SECONDARY_REGION \
  --auto-scaling-group-name "$ASG_SECONDARY" \
  --min-size 0 --desired-capacity 0
