# SOAR Security Platform

Automated security system that detects SSH brute force attacks and sends instant email alerts.

> 📐 **Architecture Diagram**: See [ARCHITECTURE.md](ARCHITECTURE.md)

## What is this?

A **SOAR** (Security Orchestration, Automation, and Response) platform that monitors Ubuntu servers 24/7 for suspicious login attempts. When brute force patterns are detected, security teams are automatically alerted via email.

## The Problem

Hackers execute thousands of automated brute force attacks on servers daily. Manual monitoring is impossible and late detection leads to successful data breaches.

## The Solution

This system:
- Continuously monitors `/var/log/auth.log` on Ubuntu server
- Detects failed SSH login attempts in real-time
- Analyzes patterns (number of attempts per IP within 2 minutes)
- Sends automatic email alerts for suspicious behavior

## How Does It Work?

```
Ubuntu Server → HTTPS → API Gateway → Lambda (VPC) → Email Alert
```

1. **Ingress**: Validates incoming events
2. **Parser**: Stores events in DynamoDB
3. **Engine**: Detects brute force patterns
4. **Notify**: Sends email via SNS

**Network Architecture:**
- Ubuntu server sends events via **HTTPS** to public API Gateway endpoint
- Lambda functions run in **private VPC subnets** for maximum security
- **VPC Endpoints** provide direct AWS service communication (DynamoDB, SQS, SNS)
- **No NAT Gateway** needed - everything via VPC endpoints (lower costs)
- **No VPN** needed - API Gateway is publicly accessible via HTTPS

## Alerts

| Attempts | Action |
|----------|--------|
| 3x | Initial warning |
| 5x | Elevated alert |
| 10x | Possible brute force |
| 15x+ | Confirmed attack |

## Technology

**AWS Serverless:**
- Lambda (event processing in VPC)
- DynamoDB (event storage)
- SQS (message queues)
- SNS (email notifications)
- API Gateway (REST API)
- VPC Endpoints (secure AWS service access)

**Infrastructure:**
- Terraform (IaC)
- GitHub Actions (CI/CD)

## Deployment

Fully automated via GitHub Actions on every push to main branch.

```bash
# Manual
cd terraform
terraform init
terraform apply
```

## Project Structure

```
casestudy2/
├── lambda/           # 4 Lambda functions
├── terraform/        # Infrastructure as Code
├── scripts/          # Helper scripts
└── .github/          # CI/CD workflows
```

## Academic Context

**Case Study 2** | Fontys University of Applied Sciences | Semester 3 | 2025  
Demonstrates cloud-native security automation and DevOps principles.

---

**Student**: Mehdi Cetinkaya
