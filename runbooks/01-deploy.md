# Runbook: Initial DR Environment Deployment

## Purpose
Provision the multi-region DR environment (primary ca-central-1, secondary us-east-1).

## Prerequisites
- AWS CLI configured and authenticated.
- CloudFormation templates present in this repository.
- IAM permissions to create VPC/EC2/ALB/ASG/Route53/S3.
- Valid AMI IDs per region (AL2023 x86_64 recommended).

## Variables (set in your shell)
PRIMARY_REGION=ca-central-1
SECONDARY_REGION=us-east-1

## 1) Deploy network stacks
aws cloudformation deploy --region $PRIMARY_REGION \
  --stack-name dr-net-primary \
  --template-file cloudformation/primary-ca-central-1/network.yaml

aws cloudformation deploy --region $SECONDARY_REGION \
  --stack-name dr-net-secondary \
  --template-file cloudformation/secondary-us-east-1/network.yaml

## 2) Discover AMIs (example AL2023 x86_64)
AMI_PRIMARY=$(aws ec2 describe-images --region $PRIMARY_REGION \
  --owners amazon --filters "Name=name,Values=al2023-ami-2023.*-x86_64" "Name=state,Values=available" \
  --query "reverse(sort_by(Images,&CreationDate))[0].ImageId" --output text)
AMI_SECONDARY=$(aws ec2 describe-images --region $SECONDARY_REGION \
  --owners amazon --filters "Name=name,Values=al2023-ami-2023.*-x86_64" "Name=state,Values=available" \
  --query "reverse(sort_by(Images,&CreationDate))[0].ImageId" --output text)

## 3) Prepare user data (Windows-safe)
USERDATA=$(base64 -w 0 user-data/nginx-bootstrap.sh 2>/dev/null || powershell -Command "[Convert]::ToBase64String([IO.File]::ReadAllBytes('user-data/nginx-bootstrap.sh'))")

## 4) Get primary subnet exports
PUB1_PRIMARY=$(aws cloudformation list-exports --region $PRIMARY_REGION --query "Exports[?Name=='dr-primary-PublicSubnet1Id'].Value" --output text)
PUB2_PRIMARY=$(aws cloudformation list-exports --region $PRIMARY_REGION --query "Exports[?Name=='dr-primary-PublicSubnet2Id'].Value" --output text)

## 5) Deploy primary compute
aws cloudformation deploy \
  --region $PRIMARY_REGION \
  --stack-name dr-cmp-primary \
  --template-file cloudformation/primary-ca-central-1/compute.yaml \
  --parameter-overrides \
    AmiId=$AMI_PRIMARY \
    PublicSubnet1Id=$PUB1_PRIMARY \
    PublicSubnet2Id=$PUB2_PRIMARY \
    UserDataScript=$USERDATA

## 6) Get secondary subnet exports
PUB1_SECONDARY=$(aws cloudformation list-exports --region $SECONDARY_REGION --query "Exports[?Name=='dr-secondary-PublicSubnet1Id'].Value" --output text)
PUB2_SECONDARY=$(aws cloudformation list-exports --region $SECONDARY_REGION --query "Exports[?Name=='dr-secondary-PublicSubnet2Id'].Value" --output text)

## 7) Deploy secondary compute (desired=0 in template)
aws cloudformation deploy \
  --region $SECONDARY_REGION \
  --stack-name dr-cmp-secondary \
  --template-file cloudformation/secondary-us-east-1/compute.yaml \
  --parameter-overrides \
    AmiId=$AMI_SECONDARY \
    PublicSubnet1Id=$PUB1_SECONDARY \
    PublicSubnet2Id=$PUB2_SECONDARY \
    UserDataScript=$USERDATA

## 8) Validate ALBs return 200
PRIMARY_ALB=$(aws cloudformation describe-stacks --region $PRIMARY_REGION --stack-name dr-cmp-primary --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)
SECONDARY_ALB=$(aws cloudformation describe-stacks --region $SECONDARY_REGION --stack-name dr-cmp-secondary --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)
curl -I "http://$PRIMARY_ALB"
curl -I "http://$SECONDARY_ALB"

## Success Criteria
- Primary/secondary ALBs return 200 OK.
- ASG in primary has 1 InService instance.
