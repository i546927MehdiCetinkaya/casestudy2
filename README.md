# Cloud Compliance Scanning Platform

Geautomatiseerde Azure cloud compliance scanning met focus op ISO 27017 en ISO 27018 standaarden.

> 📐 **Architectuur & Data Flows**: Zie [ARCHITECTURE.md](ARCHITECTURE.md) en [docs/architecture/data-flow-diagrams.md](docs/architecture/data-flow-diagrams.md)

## Wat is dit?

Een **AI-powered compliance scanning platform** dat Microsoft Azure tenants analyseert op naleving van ISO 27017 (cloud security) en ISO 27018 (cloud privacy) standaarden. Het platform biedt drie service modellen voor verschillende klantenbehoeften.

## Het probleem

Organisaties met Azure workloads hebben moeite om:
- Continue compliance te garanderen met cloud security standaarden
- Beleidsdocumentatie te valideren tegen werkelijke implementatie
- Tijdig compliance gaps te identificeren
- Historische compliance trends bij te houden

## De oplossing

Dit platform biedt drie service opties:

### 1. 🆓 Gratis Scan
- Beperkte scan van Azure tenant
- Maximaal 2 bevindingen zichtbaar (preview)
- Keuze tussen ISO 27017 of ISO 27018
- Geen document upload, geen betaling
- **Doel**: Eerste inzicht in compliance status

### 2. 💎 Premium Scan (Eenmalig)
- Pre-payment via Stripe/Mollie
- Upload van beleidsdocumenten vereist
- AI analyseert tenant + documenten
- Volledig rapport met alle compliance bevindingen
- Gedetailleerde scores en remediatie adviezen
- **Doel**: Ad-hoc compliance audit met volledige analyse

### 3. 📅 Abonnement (€99/maand)
- **1 geautomatiseerde scan per maand per tenant**
- Automatische rapportage na elke scan
- Historische trenddata en compliance tracking
- Factuur met 14 dagen betalingstermijn
- **Doel**: Continue compliance monitoring

**Belangrijke verduidelijking**: Abonnement betekent **GEEN** gratis handmatige scan, maar geeft recht op **1 automatische scan per maand**. Extra scans kunnen apart aangeschaft worden als premium scan.

## Hoe werkt het?

```
Azure Tenant → OAuth → Platform API → AI Analysis → Compliance Report
```

**Scan proces:**
1. **Autorisatie**: Azure OAuth voor tenant toegang
2. **Data collectie**: Verzamelt tenant configuratie via Azure APIs
3. **Document analyse**: AI parseert geüploade beleidsdocumenten (premium/abonnement)
4. **Compliance check**: Vergelijkt tegen ISO 27017/27018 controls
5. **Gap analysis**: Identificeert afwijkingen tussen policy en implementatie
6. **Rapportage**: Genereert rapport met scores en remediatie adviezen

## Service Vergelijking

| Feature | Gratis | Premium | Abonnement |
|---------|--------|---------|------------|
| **Prijs** | €0 | Vanaf €299 | €99/maand |
| **Bevindingen** | Max 2 (preview) | Alle | Alle |
| **Document upload** | ❌ | ✅ | ✅ |
| **AI analyse** | Basis | Volledig | Volledig |
| **Remediatie advies** | ❌ | ✅ | ✅ |
| **Historische data** | ❌ | ❌ | ✅ |
| **Frequentie** | Eenmalig | On-demand | 1x/maand (automatisch) |
| **Betaling** | N.v.t. | Vooraf | Factuur (14 dagen) |

## Technologie Stack

**Cloud Infrastructure:**
- AWS Lambda (scan processing)
- AWS DynamoDB (data storage)
- AWS S3 (document storage, encrypted)
- AWS SQS (message queues)
- AWS SNS (email notificaties)
- API Gateway (REST API)

**AI/ML:**
- Document parsing en NLP
- Compliance mapping algorithms
- Risk scoring models

**Integrations:**
- Azure Resource Manager API
- Azure Policy API
- Azure Security Center
- Stripe/Mollie (payments)

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
├── lambda/                      # Lambda functies voor scan processing
├── terraform/                   # Infrastructure as Code
├── scripts/                     # Helper scripts
├── docs/                        # Documentatie
│   ├── BUSINESSPLAN.md         # Business model en pricing
│   └── architecture/
│       └── data-flow-diagrams.md  # Service flows
├── frontend/                    # Frontend requirements
│   └── README.md               # UI/UX specificaties
└── .github/                     # CI/CD workflows
```

## Documentatie

- 📋 [Business Plan](docs/BUSINESSPLAN.md) - Service model, pricing en strategie
- 🔄 [Data Flow Diagrams](docs/architecture/data-flow-diagrams.md) - Gedetailleerde flows per service
- 🎨 [Frontend Requirements](frontend/README.md) - UI/UX specificaties en user journeys
- 🏗️ [Architecture](ARCHITECTURE.md) - Technische architectuur

## Compliance Standards

**ISO 27017**: Security controls for cloud services
- Cloud-specific security controls
- Shared responsibility model
- Cloud service provider responsibilities

**ISO 27018**: Privacy controls for public cloud
- PII protection in cloud
- Transparency in data processing
- Customer data control

## Target Market

- Nederlandse bedrijven met Azure workloads
- Organisaties met ISO 27017/27018 certificering ambities
- Bedrijven met compliance vereisten (GDPR, NIS2)
- MSP's en cloud consultancy bedrijven

## Academic Context

**Case Study 2** | Fontys Hogeschool | Semester 3 | 2025  
Demonstreert cloud-native compliance automation, AI integratie en SaaS business modellen.

---

**Student**: Mehdi Cetinkaya
