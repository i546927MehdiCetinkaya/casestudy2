# SOAR Security Platform

Geautomatiseerd beveiligingssysteem dat SSH brute force aanvallen detecteert en direct email waarschuwingen verstuurt.

> 📐 **Architectuur diagram**: Zie [ARCHITECTURE.md](ARCHITECTURE.md)

## Wat is dit?

Een **SOAR** (Security Orchestration, Automation, and Response) platform dat 24/7 Ubuntu servers monitort op verdachte inlogpogingen. Bij detectie van brute force patronen worden security teams automatisch gealarmeerd via email.

## Het probleem

Hackers voeren dagelijks duizenden geautomatiseerde brute force aanvallen uit op servers. Handmatige monitoring is onmogelijk en late detectie leidt tot succesvolle datalekken.

## De oplossing

Dit systeem:
- Monitort continu `/var/log/auth.log` op Ubuntu server
- Detecteert mislukte SSH-inlogpogingen in real-time
- Analyseert patronen (aantal pogingen per IP binnen 2 minuten)
- Verstuurt automatische email alerts bij verdacht gedrag

## Hoe werkt het?

```
Ubuntu Server → HTTPS → API Gateway → Lambda (VPC) → Email Alert
```

1. **Ingress**: Valideert inkomende events
2. **Parser**: Slaat events op in DynamoDB
3. **Engine**: Detecteert brute force patronen
4. **Notify**: Verstuurt email via SNS

**Netwerk Architectuur:**
- Ubuntu server stuurt events via **HTTPS** naar publieke API Gateway endpoint
- Lambda functies draaien in **private VPC subnets** voor maximale security
- **VPC Endpoints** zorgen voor directe AWS service communicatie (DynamoDB, SQS, SNS)
- **Geen NAT Gateway** nodig - alles via VPC endpoints (lagere kosten)
- **Geen VPN** nodig - API Gateway is publiek bereikbaar via HTTPS

## Waarschuwingen

| Pogingen | Actie |
|----------|-------|
| 3x | Eerste waarschuwing |
| 5x | Verhoogd alarm |
| 10x | Mogelijk brute force |
| 15x+ | Bevestigde aanval |

## Technologie

**AWS Serverless:**
- Lambda (event processing in VPC)
- DynamoDB (event storage)
- SQS (message queues)
- SNS (email notificaties)
- API Gateway (REST API)
- VPC Endpoints (secure AWS service access)

**Infrastructure:**
- Terraform (IaC)
- GitHub Actions (CI/CD)

## Deployment

Volledig geautomatiseerd via GitHub Actions bij elke push naar main branch.

```bash
# Handmatig
cd terraform
terraform init
terraform apply
```

## Project Structuur

```
casestudy2/
├── lambda/           # 5 Lambda functies
├── terraform/        # Infrastructure as Code
├── scripts/          # Helper scripts
└── .github/          # CI/CD workflows
```

## Academic Context

**Case Study 2** | Fontys Hogeschool | Semester 3 | 2025  
Demonstreert cloud-native security automation en DevOps principes.

---

**Student**: Mehdi Cetinkaya
