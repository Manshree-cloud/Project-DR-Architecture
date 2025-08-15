# Project 1 — Multi-Region Disaster Recovery (Day 1 Starter)

**Primary Region (today):** `ca-central-1` (Canada Central)  
**Goal (Day 1 ~90 min):** Repo + baseline VPC + single EC2 via ASG in public subnets using CloudFormation. NGINX serves a page showing region & instance ID.

## Repo Name
`aws-multiregion-dr-architecture`

## Folder Structure
```
Project1-DR-Architecture/
├─ cloudformation/
│  └─ network-app.yml
├─ scripts/
│  └─ deploy-primary.sh
├─ diagrams/
├─ demo/
│  └─ failover-test-screenshots/
└─ .gitignore
```

## Prereqs
- AWS CLI v2 configured (`aws configure`) with a profile that has permissions to create VPC, EC2, ASG, and IAM (no custom IAM resources used on Day 1).
- Key pair in `ca-central-1` (for optional SSH), or create one from EC2 Console.
- (Optional) GitHub account ready for new repo.

## Quick Start (Primary Region Deploy)
1. Validate template:
   ```bash
   aws cloudformation validate-template --template-body file://cloudformation/network-app.yml
   ```
2. Deploy (replace placeholders as needed):
   ```bash
   bash scripts/deploy-primary.sh
   ```
3. After CREATE_COMPLETE, get public DNS of instance via EC2 console or:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=dr-primary-asg"      --region ca-central-1 --query "Reservations[].Instances[].PublicDnsName" --output text
   ```
   Open `http://<public-dns>` to see the NGINX page showing region and instance metadata.

## Clean Up (to avoid charges)
```bash
aws cloudformation delete-stack --stack-name dr-primary --region ca-central-1
aws cloudformation wait stack-delete-complete --stack-name dr-primary --region ca-central-1
```


