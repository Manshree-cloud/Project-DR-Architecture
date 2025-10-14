#!/usr/bin/env bash
set -euo pipefail

# Ensure env is loaded
: "${TEST_ZONE_ID:?missing}"; : "${TEST_ZONE_NAME:?missing}"
: "${PRIMARY_REGION:?missing}"; : "${SECONDARY_REGION:?missing}"
: "${PRIMARY_ALB:?missing}"; : "${SECONDARY_ALB:?missing}"
: "${ASG_PRIMARY:?missing}"; : "${ASG_SECONDARY:?missing}"

say() { printf "\n\033[1m%s\033[0m\n" "$*"; }

say "DNS (expected primary):"
aws route53 test-dns-answer \
  --hosted-zone-id "$TEST_ZONE_ID" \
  --record-name "www.${TEST_ZONE_NAME}.com" \
  --record-type A

say "Primary ALB (expect 200 OK):"
curl -I "http://${PRIMARY_ALB}" || true

say "Simulating outage: set primary Min=0, Desired=0"
aws autoscaling update-auto-scaling-group \
  --region "$PRIMARY_REGION" \
  --auto-scaling-group-name "$ASG_PRIMARY" \
  --min-size 0
aws autoscaling set-desired-capacity \
  --region "$PRIMARY_REGION" \
  --auto-scaling-group-name "$ASG_PRIMARY" \
  --desired-capacity 0

say "Optionally ensure secondary has capacity (Desired=1)"
aws autoscaling set-desired-capacity \
  --region "$SECONDARY_REGION" \
  --auto-scaling-group-name "$ASG_SECONDARY" \
  --desired-capacity 1

say "Waiting ~75s for health to update..."
sleep 75

say "DNS (expected secondary now):"
aws route53 test-dns-answer \
  --hosted-zone-id "$TEST_ZONE_ID" \
  --record-name "www.${TEST_ZONE_NAME}.com" \
  --record-type A

say "Secondary ALB (expect 200 OK):"
curl -I "http://${SECONDARY_ALB}" || true

say "Restoring primary: Min=1, Desired=1"
aws autoscaling update-auto-scaling-group \
  --region "$PRIMARY_REGION" \
  --auto-scaling-group-name "$ASG_PRIMARY" \
  --min-size 1
aws autoscaling set-desired-capacity \
  --region "$PRIMARY_REGION" \
  --auto-scaling-group-name "$ASG_PRIMARY" \
  --desired-capacity 1

say "Done."
