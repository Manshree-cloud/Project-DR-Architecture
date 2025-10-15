# Runbook: Pause & Resume (Cost Control)

Purpose: minimize spend by pausing compute (ASGs to 0) and resuming later without redeploying.

## Variables
PRIMARY_REGION=ca-central-1
SECONDARY_REGION=us-east-1

## Pause (evening)
./scripts/pause_env.sh

Verify:
aws autoscaling describe-auto-scaling-groups --region $PRIMARY_REGION \
  --auto-scaling-group-names "$(aws cloudformation describe-stacks --region $PRIMARY_REGION --stack-name dr-cmp-primary --query "Stacks[0].Outputs[?OutputKey=='AsgName'].OutputValue" --output text)" \
  --query "AutoScalingGroups[0].{Desired:DesiredCapacity,Min:MinSize,States:Instances[].LifecycleState}"

## Resume (morning)
./scripts/resume_env.sh

Validate ALB:
PRIMARY_ALB=$(aws cloudformation describe-stacks --region $PRIMARY_REGION --stack-name dr-cmp-primary --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)
SECONDARY_ALB=$(aws cloudformation describe-stacks --region $SECONDARY_REGION --stack-name dr-cmp-secondary --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)
curl -I "http://$PRIMARY_ALB"
curl -I "http://$SECONDARY_ALB"

Notes:
- ALBs still cost a small amount; pause is focused on EC2/ASG.
- If resume fails due to AMI/userdata changes, redeploy compute stack.
