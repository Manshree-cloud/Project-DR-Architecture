# 🏗️ Project DR Architecture — Multi-Region AWS Disaster Recovery 

This repository contains a **cost-aware two-region Disaster Recovery (DR) reference architecture on AWS** using CloudFormation.  
It showcases how to architect, deploy, and fail over a simple workload between regions in minutes.

---

## ✨ Key Highlights 

- **Architected a cost-aware two-region DR reference using custom VPCs, EC2 Launch Templates + ASG, and CloudFormation templates for reproducibility and peer review.**  
- **Implemented S3 Cross-Region Replication (versioning + SSE) and validated failover; enforced IAM replication roles and least-privilege access for durability and security.**  
- **Integrated monitoring, identity management, and failover automation into enterprise systems to ensure continuity with <5 min RTO with before/after validation screenshots.**  
- **Configured CloudWatch alarms + SNS alerts (ASG health, EC2 CPU) for operational signaling; documented runbooks, diagrams, and recovery/cleanup steps.**  
- **Applied Infrastructure as Code principles using CloudFormation and began modular Terraform prototypes for DR provisioning (state mgmt. via S3+DynamoDB), demonstrating cross-tool IaC capability.**  
- **Mapped AWS patterns to Azure/GCP equivalents (EC2/ASG→VMSS, S3→Blob, CloudWatch→Monitor/Log Analytics, IAM→RBAC; Lambda→Functions/Run).**

---

## 🏗️ Architecture Overview

- **Primary Region:** `ca-central-1` 🇨🇦  
- **Secondary Region:** `us-east-1` 🇺🇸  
- **Core Components:**
  - VPC, Public Subnets, ALB + ASG (EC2 NGINX “Hello from REGION”)
  - Route 53 DNS failover with Health Checks
  - S3 Cross-Region Replication
  - CloudWatch + SNS for monitoring and alerting
  - IAM least privilege for replication and automation
  - IaC using CloudFormation with Terraform scaffold for future portability

---

## 📂 Folder Structure
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
```
 📊 DR Failover Demo — Route 53 + ALB

| Step | Description                           | Evidence |
|------|---------------------------------------|-----------|
| 1    | Initial DNS points to primary (ca-central-1) | ![dns_primary](docs/dns_primary.png) |
| 2    | Primary ALB returns 200 OK | ![primary_200](docs/primary_200.png) |
| 3    | Primary ASG scaled to 0 | ![asg_down](docs/asg_down.png) |
| 4    | Route 53 switches to secondary (us-east-1) | ![dns_secondary](docs/dns_secondary.png) |
| 5    | Secondary ALB returns 200 OK | ![secondary_200](docs/secondary_200.png) |

✅ **Failover succeeded in under 5 minutes without manual DNS changes.**

## 🎥 Demo Video
[AWS DR Failover — Route 53 to ALB (1:30)](./docs/aws-dr-failover-demo.mp4)

