# Runbook: Alarms and Evidence Capture

## Purpose
Configure alarms and capture proof (screenshots) of failover for audit/interview.

## SNS Topic
TOPIC_ARN=$(aws sns create-topic --name dr-alerts --region ca-central-1 --query TopicArn --output text)
aws sns subscribe --region ca-central-1 --topic-arn "$TOPIC_ARN" --protocol email --notification-endpoint "you@example.com"
# Confirm the email subscription from your inbox.

## Target Group Alarm (HealthyHostCount < 1)
TG_ARN_PRIMARY=$(aws elbv2 describe-target-groups --region ca-central-1 --query "TargetGroups[0].TargetGroupArn" --output text)
aws cloudwatch put-metric-alarm --region ca-central-1 \
  --alarm-name "dr-primary-tg-healthyhosts-lt1" \
  --alarm-description "Primary TG healthy hosts < 1" \
  --namespace AWS/ApplicationELB \
  --metric-name HealthyHostCount \
  --statistic Average --period 60 --evaluation-periods 2 --threshold 1 \
  --comparison-operator LessThanThreshold \
  --dimensions Name=TargetGroup,Value=$TG_ARN_PRIMARY \
  --treat-missing-data breaching \
  --alarm-actions "$TOPIC_ARN"

## ASG Alarm (InServiceInstances < 1)
ASG_PRIMARY=$(aws cloudformation describe-stacks --region ca-central-1 --stack-name dr-cmp-primary --query "Stacks[0].Outputs[?OutputKey=='AsgName'].OutputValue" --output text)
aws cloudwatch put-metric-alarm --region ca-central-1 \
  --alarm-name "dr-primary-asg-inservice-lt1" \
  --alarm-description "Primary ASG InServiceInstances < 1" \
  --namespace AWS/AutoScaling \
  --metric-name GroupInServiceInstances \
  --statistic Average --period 60 --evaluation-periods 2 --threshold 1 \
  --comparison-operator LessThanThreshold \
  --dimensions Name=AutoScalingGroupName,Value=$ASG_PRIMARY \
  --treat-missing-data breaching \
  --alarm-actions "$TOPIC_ARN"

## Evidence to capture (store in docs/)
- DNS answer: before/after.
- Primary/secondary ALB curl outputs.
- CloudWatch Alarms page showing ALARM -> OK transitions.
- Route 53 record sets view (weighted/alias).
