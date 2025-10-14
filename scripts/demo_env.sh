#!/usr/bin/env bash
set -euo pipefail

# ---- EDIT THIS ONE VALUE (your test zone name without trailing dot) ----
: "${TEST_ZONE_NAME:=dr-demo-example}"   # <--- change if you used a different name

# Regions you used
: "${PRIMARY_REGION:=ca-central-1}"
: "${SECONDARY_REGION:=us-east-1}"

# Hosted zone id (by name)
TEST_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='${TEST_ZONE_NAME}.com.'].Id | [0]" \
  --output text)
TEST_ZONE_ID=${TEST_ZONE_ID##*/}

# CloudFormation outputs/physical IDs
PRIMARY_ALB=$(aws cloudformation describe-stacks --region "$PRIMARY_REGION" --stack-name dr-cmp-primary \
  --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)
SECONDARY_ALB=$(aws cloudformation describe-stacks --region "$SECONDARY_REGION" --stack-name dr-cmp-secondary \
  --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)

ASG_PRIMARY=$(aws cloudformation describe-stacks --region "$PRIMARY_REGION" --stack-name dr-cmp-primary \
  --query "Stacks[0].Outputs[?OutputKey=='AsgName'].OutputValue" --output text)
ASG_SECONDARY=$(aws cloudformation describe-stacks --region "$SECONDARY_REGION" --stack-name dr-cmp-secondary \
  --query "Stacks[0].Outputs[?OutputKey=='AsgName'].OutputValue" --output text)

export TEST_ZONE_NAME TEST_ZONE_ID PRIMARY_REGION SECONDARY_REGION \
       PRIMARY_ALB SECONDARY_ALB ASG_PRIMARY ASG_SECONDARY

echo "Loaded demo env:"
echo "  TEST_ZONE_NAME=$TEST_ZONE_NAME"
echo "  TEST_ZONE_ID=$TEST_ZONE_ID"
echo "  PRIMARY_REGION=$PRIMARY_REGION"
echo "  SECONDARY_REGION=$SECONDARY_REGION"
echo "  PRIMARY_ALB=$PRIMARY_ALB"
echo "  SECONDARY_ALB=$SECONDARY_ALB"
echo "  ASG_PRIMARY=$ASG_PRIMARY"
echo "  ASG_SECONDARY=$ASG_SECONDARY"
