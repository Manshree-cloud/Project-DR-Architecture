# Runbook: Rollback to Primary and Cost Cleanup

## Purpose
Return traffic to primary, then minimize costs.

## Variables
PRIMARY_REGION=ca-central-1
SECONDARY_REGION=us-east-1
ASG_PRIMARY=$(aws cloudformation describe-stacks --region $PRIMARY_REGION --stack-name dr-cmp-primary --query "Stacks[0].Outputs[?OutputKey=='AsgName'].OutputValue" --output text)
ASG_SECONDARY=$(aws cloudformation describe-stacks --region $SECONDARY_REGION --stack-name dr-cmp-secondary --query "Stacks[0].Outputs[?OutputKey=='AsgName'].OutputValue" --output text)

## 1) Scale up primary
aws autoscaling update-auto-scaling-group --region $PRIMARY_REGION \
  --auto-scaling-group-name "$ASG_PRIMARY" \
  --min-size 1 --desired-capacity 1 --max-size 2

## 2) Wait for TG healthy and DNS to shift back (if failover is health based)

## 3) Optional: scale down secondary
aws autoscaling update-auto-scaling-group --region $SECONDARY_REGION \
  --auto-scaling-group-name "$ASG_SECONDARY" \
  --min-size 0 --desired-capacity 0 --max-size 2

## 4) Optional tear-down to save cost (irreversible)
# aws cloudformation delete-stack --stack-name dr-cmp-primary --region $PRIMARY_REGION
# aws cloudformation delete-stack --stack-name dr-cmp-secondary --region $SECONDARY_REGION
# aws cloudformation delete-stack --stack-name dr-net-primary --region $PRIMARY_REGION
# aws cloudformation delete-stack --stack-name dr-net-secondary --region $SECONDARY_REGION

## Success Criteria
- Primary ASG serving 200 OK.
- Secondary scaled down if not needed.
- No unnecessary running resources left overnight.
