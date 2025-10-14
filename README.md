# Project 1 — Multi-Region Disaster Recovery 

**Primary Region:** `ca-central-1` (Canada Central)  
**Goal :** Repo + baseline VPC + single EC2 via ASG in public subnets using CloudFormation. NGINX serves a page showing region & instance ID.

## Repo Name
`aws-multiregion-dr-architecture`

## Folder Structure
```
aws-multi-region-dr-reference/
├─ README.md
├─ diagrams/
│  └─ dr-architecture.drawio  (export PNG later)
├─ cloudformation/
│  ├─ primary-ca-central-1/
│  │  ├─ network.yaml            # VPC, subnets, IGW, NAT, route tables
│  │  ├─ compute.yaml            # LT, ASG, ALB, SGs, TargetGroup, Listener
│  │  ├─ s3-primary.yaml         # Primary S3 bucket (versioning, SSE)
│  │  └─ outputs.md
│  ├─ secondary-us-east-1/
│  │  ├─ network.yaml
│  │  ├─ compute.yaml
│  │  ├─ s3-secondary.yaml       # Secondary S3 bucket + replication role trust
│  │  └─ outputs.md
│  └─ global/
│     ├─ route53-failover.yaml   # Hosted zone records + health check
│     └─ sns-alarms.yaml         # SNS topic + subscriptions, CW alarms
├─ user-data/
│  └─ nginx-bootstrap.sh         # prints “Hello from $REGION”
├─ runbooks/
│  ├─ 01-deploy.md
│  ├─ 02-failover-test.md
│  ├─ 03-rollback-cleanup.md
│  └─ 04-alarms-and-screenshots.md
├─ terraform-prototype/
│  ├─ modules/
│  │  └─ vpc/ (scaffold only)
│  └─ main.tf  (commented placeholders)
└─ scripts/
   ├─ deploy_primary.sh
   ├─ deploy_secondary.sh
   ├─ setup_replication.sh
   └─ teardown.sh

