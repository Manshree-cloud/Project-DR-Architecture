# Runbook: Route 53 Weighted Failover Drill

## Purpose
Simulate primary outage and observe DNS routing to secondary. Demonstrate RTO under 5 minutes.

## Prerequisites
- Weighted alias A record to both ALBs with EvaluateTargetHealth=true.
- Health check path "/" on Target Groups.
- TTL <= 30 seconds recommended.

## Variables
PRIMARY_REGION=ca-central-1
SECONDARY_REGION=us-east-1

## 1) Identify ASG and ALB
ASG_PRIMARY=$(aws cloudformation describe-stacks --region $PRIMARY_REGION --stack-name dr-cmp-primary --query "Stacks[0].Outputs[?OutputKey=='AsgName'].OutputValue" --output text)
PRIMARY_ALB=$(aws cloudformation describe-stacks --region $PRIMARY_REGION --stack-name dr-cmp-primary --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)
SECONDARY_ALB=$(aws cloudformation describe-stacks --region $SECONDARY_REGION --stack-name dr-cmp-secondary --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)

## 2) Baseline checks
curl -I "http://$PRIMARY_ALB"
curl -I "http://$SECONDARY_ALB"

## 3) Induce failure (scale primary to 0)
aws autoscaling update-auto-scaling-group --region $PRIMARY_REGION \
  --auto-scaling-group-name "$ASG_PRIMARY" \
  --min-size 0 --desired-capacity 0 --max-size 2

## 4) Wait 1-3 minutes for health propagation and TTL expiry

## 5) Validate DNS resolves to secondary
# Replace the record with your test record name if different
# Example:
# nslookup www.dr-demo.test
# curl -I http://www.dr-demo.test

## Success Criteria
- Route 53 answers with secondary ALB.
- Secondary ALB returns 200 OK.
