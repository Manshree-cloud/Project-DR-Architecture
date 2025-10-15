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


| 🔹  | Initial DNS points to primary (ca-central-1) | ![dns_primary](docs/dns_primary.png) |
| 🔹  | Primary ALB returns 200 OK | ![primary_200](docs/primary_200.png) |

| 🔹  | Route 53 switches to secondary (us-east-1) | ![dns_secondary](docs/dns_secondary.png) |
| 🔹  | Secondary ALB returns 200 OK | ![secondary_200](docs/secondary_200.png) |

|️ 🔹 | Primary VPC + subnets deployed successfully   | ![vpc_create](docs/vpc_create.png) |
| 🔹 | Secondary VPC + subnets deployed              | ![vpc_secondary](docs/vpc_secondary.png) |
| 🔹 | Primary ALB + ASG stack completed             | ![compute_primary](docs/compute_primary.png) |
| 🔹 | Secondary ALB + ASG stack completed           | ![compute_secondary](docs/compute_secondary.png) |
| 🔹 | Route 53 hosted zone with weighted alias      | ![route53_hosted_zone](docs/route53_hosted_zone.png) |
| 🔹 | DNS initially pointing to primary ALB         | ![ALB_dns_primary & secondary](docs/ALB_dns_primary%20&%20secondary.png) |

---

## 🪣 S3 Cross-Region Replication



| 🔹 | Primary S3 bucket — versioning + encryption on  | ![s3_primary_bucket](docs/s3-primary_bucket.png) |
| 🔹 | Secondary S3 bucket — destination configured   | ![s3_secondary_bucket](docs/s3-secondary_bucket.png) |
| 🔹 | Object successfully replicated across regions | ![s3_object_replicated](docs/s3_object_replicated.png) |



## 🛰️ Route 53 DR Failover Demo (RTO < 5 min)


| 🔹 | Primary ALB healthy (200 OK)                    | ![primary_200](docs/primary_200.png) |
| 🔹 | TG health check failure simulated               | ![tg_healthcheck](docs/tg_healthcheck.png) |
| 🔹 | DNS switches to secondary automatically        | ![dns_secondary](docs/dns_secondary.png) |
| 🔹 | Secondary ALB healthy (200 OK)                 | ![secondary_200](docs/secondary_200.png) |


## 📡 CloudWatch Alarms & SNS Notifications

| 🔸 | Target Group alarm fired              | ![alarm_tgpng](docs/alarm_tgpng.png) |
| 🔸 | ASG InService alarm fired             | ![alarm_asg](docs/alarm_asg.png) |
| 🔸 | Email notification received          | *(You can add a screenshot of your inbox here)* |

---
✅ **Failover succeeded in under 5 minutes without manual DNS changes.**

## 🎥 Demo Video
[![Watch the demo](docs/thumbnail.png)](https://github.com/Manshree-cloud/Project-DR-Architecture/raw/main/docs/aws-dr-failover-demo.mp4)
