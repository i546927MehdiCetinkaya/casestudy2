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
Ubuntu Server → VPN → API Gateway → Lambda Pipeline → Email Alert
```

1. **Ingress**: Valideert inkomende events
2. **Parser**: Slaat events op in DynamoDB
3. **Engine**: Detecteert brute force patronen
4. **Notify**: Verstuurt email via SNS

## Waarschuwingen

| Pogingen | Actie |
|----------|-------|
| 3x | Eerste waarschuwing |
| 5x | Verhoogd alarm |
| 10x | Mogelijk brute force |
| 15x+ | Bevestigde aanval |

## Technologie

**AWS Serverless:**
- Lambda (event processing)
- DynamoDB (event storage)
- SQS (message queues)
- SNS (email notificaties)
- API Gateway (REST API)
- VPN (site-to-site verbinding)

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
