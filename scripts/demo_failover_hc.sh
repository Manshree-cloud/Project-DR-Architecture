#!/usr/bin/env bash
set -euo pipefail

# Ensure env variables are loaded (from scripts/demo_env.sh)
: "${PRIMARY_REGION:?missing}"; : "${SECONDARY_REGION:?missing}"
: "${TEST_ZONE_ID:?missing}"; : "${TEST_ZONE_NAME:?missing}"
: "${PRIMARY_ALB:?missing}"; : "${SECONDARY_ALB:?missing}"
: "${ASG_PRIMARY:?missing}"

say() { printf "\n\033[1m%s\033[0m\n" "$*"; }

# Discover primary Target Group ARN and build CW dimension form
TG_ARN_PRIMARY=$(aws cloudformation describe-stack-resources \
  --region "$PRIMARY_REGION" \
  --stack-name dr-cmp-primary \
  --query "StackResources[?LogicalResourceId=='TargetGroup'].PhysicalResourceId" \
  --output text)

if [ -z "$TG_ARN_PRIMARY" ] || [ "$TG_ARN_PRIMARY" = "None" ]; then
  echo "ERROR: Could not find TargetGroup ARN from stack dr-cmp-primary." 1>&2
  exit 1
fi

say "Baseline: Route 53 should answer PRIMARY"
aws route53 test-dns-answer \
  --hosted-zone-id "$TEST_ZONE_ID" \
  --record-name "www.${TEST_ZONE_NAME}.com" \
  --record-type A

say "Baseline: Primary ALB (expect 200 OK)"
curl -I "http://${PRIMARY_ALB}" || true

say "Make primary unhealthy (change TG health-check-path to /this-will-fail)"
# Avoid Git Bash path conversion
MSYS_NO_PATHCONV=1 aws elbv2 modify-target-group \
  --region "$PRIMARY_REGION" \
  --target-group-arn "$TG_ARN_PRIMARY" \
  --health-check-path "/this-will-fail"

say "Waiting for primary TG to go UNHEALTHY..."
# Poll target health until it's 'unhealthy' or timeout (~120s)
DEADLINE=$((SECONDS+180))
while :; do
  STATE=$(aws elbv2 describe-target-health \
    --region "$PRIMARY_REGION" \
    --target-group-arn "$TG_ARN_PRIMARY" \
    --query "TargetHealthDescriptions[0].TargetHealth.State" \
    --output text 2>/dev/null || echo "unknown")
  echo "  current target health: $STATE"
  if [ "$STATE" = "unhealthy" ] || [ "$STATE" = "unused" ] || [ "$STATE" = "draining" ]; then
    break
  fi
  [ $SECONDS -gt $DEADLINE ] && { echo "Timeout waiting for TG unhealthy."; break; }
  sleep 10
done

say "Ask Route 53 again (should flip to SECONDARY)"
aws route53 test-dns-answer \
  --hosted-zone-id "$TEST_ZONE_ID" \
  --record-name "www.${TEST_ZONE_NAME}.com" \
  --record-type A

say "Secondary ALB (expect 200 OK)"
curl -I "http://${SECONDARY_ALB}" || true

say "Restore primary health-check-path to '/'"
MSYS_NO_PATHCONV=1 aws elbv2 modify-target-group \
  --region "$PRIMARY_REGION" \
  --target-group-arn "$TG_ARN_PRIMARY" \
  --health-check-path "/"

say "Waiting for primary TG to return to HEALTHY..."
DEADLINE=$((SECONDS+240))
while :; do
  STATE=$(aws elbv2 describe-target-health \
    --region "$PRIMARY_REGION" \
    --target-group-arn "$TG_ARN_PRIMARY" \
    --query "TargetHealthDescriptions[0].TargetHealth.State" \
    --output text 2>/dev/null || echo "unknown")
  echo "  current target health: $STATE"
  [ "$STATE" = "healthy" ] && break
  [ $SECONDS -gt $DEADLINE ] && { echo "Timeout waiting for TG healthy."; break; }
  sleep 10
done

say "Primary ALB (should be 200 OK again)"
curl -I "http://${PRIMARY_ALB}" || true

say "Ask Route 53 (it will prefer PRIMARY once healthy)"
aws route53 test-dns-answer \
  --hosted-zone-id "$TEST_ZONE_ID" \
  --record-name "www.${TEST_ZONE_NAME}.com" \
  --record-type A

say "Done."
