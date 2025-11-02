# Gebruikersreis - Cloud Compliance Scanning Platform

## Overview

Dit document beschrijft de complete gebruikersreizen voor alle drie de service tiers, met focus op touchpoints, beslismomenten en conversie opportunities.

---

## Journey 1: Gratis Scan Gebruiker

### Persona: Trial Tommy
**Profiel:**
- IT Manager bij MKB bedrijf (50-200 medewerkers)
- Verantwoordelijk voor cloud security
- Zoekt naar compliance oplossing
- Budget bewust, wil eerst testen

### Reis Stappen

#### 1. Awareness (Website bezoek)
**Touchpoint:** Landing page

**Gebruiker ziet:**
- Hero message: "Controleer uw Azure compliance in minuten"
- 3 service cards (Gratis, Premium, Abonnement)
- USP's: AI-powered, ISO 27017/27018, Nederlandse expertise

**Actie:** Klikt op "Start gratis scan"

#### 2. Onboarding (Service selectie)
**Touchpoint:** Scan configuratie pagina

**Gebruiker doet:**
- Kiest tussen ISO 27017 of ISO 27018
- Leest uitleg van elk standaard
- Begrijpt: "Max 2 bevindingen zichtbaar (preview)"

**Actie:** Klikt op "Start scan" → Azure OAuth

#### 3. Autorisatie (Azure consent)
**Touchpoint:** Azure OAuth scherm

**Gebruiker ziet:**
- Welke permissies gevraagd worden (read-only)
- Privacy informatie
- Wat er gescand wordt

**Actie:** Authoriseert tenant toegang

#### 4. Processing (Scan uitvoering)
**Touchpoint:** Progress scherm

**Gebruiker ziet:**
- Loading indicator (2-5 minuten)
- Status updates:
  - "Verbinding maken met Azure..."
  - "Tenant configuratie ophalen..."
  - "Compliance analyse uitvoeren..."
  - "Rapport genereren..."

**Emotie:** Anticipation, nieuwsgierigheid

#### 5. Results (Preview rapport)
**Touchpoint:** Resultaten pagina

**Gebruiker ziet:**
- **Compliance score: 68/100** (met lock icon op details)
- **2 kritieke bevindingen zichtbaar:**
  - Finding 1: Storage accounts niet encrypted
  - Finding 2: Multi-factor authentication niet verplicht
- **8+ bevindingen verborgen** (grayed out cards)
- Melding: "Upgrade voor volledige analyse en remediatie adviezen"

**Call-to-Action:**
- Primaire CTA: "Upgrade naar Premium Scan - €299"
- Secondaire CTA: "Bekijk Abonnement opties"
- Tertiaire: "Download sample rapport"

**Emotie:** Frustratie (beperkte info) + Nieuwsgierigheid (wat zijn andere issues?)

#### 6. Decision Point
**Gebruiker overweegt:**
- ✅ "Deze 2 issues zijn al ernstig, wat zijn de rest?"
- ✅ "Ik wil complete lijst + remediatie adviezen"
- ❌ "Te duur voor nu, kom later terug"
- ❌ "Wil eerst met management overleggen"

**Conversie scenario's:**

##### 6A. Direct upgrade naar Premium
- Klikt op "Upgrade naar Premium"
- Gaat naar Premium flow (zie Journey 2)
- **Conversie: 15-20%**

##### 6B. Bekijkt abonnement info
- Leest over €99/maand voor continue monitoring
- Ziet waarde in historische trends
- **Conversie: 5-10%**

##### 6C. Verlaat zonder conversie
- Receives follow-up email (24 uur later):
  - Herinnering aan beperkte resultaten
  - Case study van vergelijkbaar bedrijf
  - Tijdelijke korting (10% off eerste premium scan)
- **Conversie via email: 5-8%**

---

## Journey 2: Premium Scan Klant

### Persona: Compliant Clara
**Profiel:**
- Security Officer bij scale-up (100-500 medewerkers)
- Gaat voor ISO 27017 certificering
- Budget beschikbaar voor compliance tooling
- Wil professioneel rapport voor auditor

### Reis Stappen

#### 1. Entry Point
**Scenario A:** Direct vanaf landing page
**Scenario B:** Upgrade vanuit gratis scan
**Scenario C:** Via Google search "Azure ISO 27017 scan"

**Touchpoint:** Premium service pagina

#### 2. Information Gathering
**Gebruiker doet:**
- Leest feature lijst
- Bekijkt sample rapport
- Checkt pricing (€299-€799)
- Leest testimonials
- Controleert FAQ

**Bezwaren die opgelost worden:**
- "Is AI analyse betrouwbaar?" → Case studies
- "Hoe lang duurt het?" → 24-48 uur SLA
- "Kan ik het delen met auditor?" → PDF export
- "Krijg ik support?" → Email support included

#### 3. Document Upload
**Touchpoint:** Upload interface

**Gebruiker upload:**
- Information Security Policy (PDF)
- Data Protection Policy (DOCX)
- Access Control procedures (PDF)
- Incident Response plan (PDF)

**System feedback:**
- File validation (max 50MB, supported formats)
- Upload progress per document
- Success confirmations

**Emotie:** Commitment (dit wordt serieus)

#### 4. ISO Standaard Selectie
**Touchpoint:** Standaard configuratie

**Gebruiker kiest:**
- ISO 27017 (cloud security) - most common
- ISO 27018 (cloud privacy)
- Beide (+€100) - comprehensive option

**Hulp:** Recommendation engine based on tenant type

#### 5. Payment
**Touchpoint:** Checkout pagina

**Gebruiker ziet:**
- Order summary:
  - Premium Scan - Medium tenant: €499
  - ISO 27017 standaard: Included
  - ISO 27018 standaard: +€100
  - **Totaal: €599 excl. BTW (€725.29 incl.)**
- Payment options:
  - Credit card (Stripe) - instant
  - iDEAL (Mollie) - instant
  - SEPA (Mollie) - 2-3 dagen

**Trust elements:**
- SSL badge
- Payment provider logos
- "Geld terug garantie"
- Recent transactions ticker

**Actie:** Betaalt met iDEAL

**Emotie:** Nerveus (grote investering) maar vertrouwen door social proof

#### 6. Payment Confirmation
**Touchpoint:** Success pagina + Email

**Gebruiker ontvangt:**
- On-screen bevestiging
- Immediate email met:
  - Payment receipt
  - Order number
  - "Scan start binnen 15 minuten"
  - Support contact info

**Emotie:** Relief, anticipation

#### 7. Azure Authorization
**Touchpoint:** OAuth flow (same as free tier)

**Gebruiker:** Authoriseert tenant access

#### 8. Processing (Extended)
**Touchpoint:** Progress tracking pagina

**Updates (real-time):**
- ✅ Documents uploaded (complete)
- ⏳ Parsing documents... (15 min)
- ⏳ Scanning tenant... (20 min)
- ⏳ AI analysis... (30 min)
- ⏳ Generating report... (10 min)

**Email updates:**
- "Scan gestart"
- "Documents verwerkt"
- "Analyse 50% compleet"
- **"Rapport klaar!" (with download link)**

**Timeline:** 24-48 uur (meestal < 24u)

#### 9. Report Ready
**Touchpoint:** Email notification + Dashboard

**Gebruiker krijgt:**
- Email met download link
- Dashboard access met:
  - Executive summary
  - Compliance score: 72/100
  - 24 bevindingen (6 critical, 8 high, 7 medium, 3 low)
  - Gap analysis: policy vs implementation
  - Remediatie roadmap

**Report sections:**
1. Executive Summary
2. Compliance Score Breakdown
3. All Findings (detailed)
4. Gap Analysis
5. Risk Assessment
6. Remediation Roadmap
7. Appendices

**Export opties:**
- Download PDF (voor auditor)
- Export Excel (voor tracking)
- Share link (beveiligd)

#### 10. Post-Purchase
**Gebruiker doet:**
- Deelt rapport met management
- Presenteert aan auditor
- Start remediation work
- Tracks progress in Excel

**Emotie:** Satisfied, empowered (knows what to fix)

#### 11. Retention Opportunity
**Email flow (na 30 dagen):**
- "Hoe gaat het met remediatie?"
- "Wil je een re-scan om vooruitgang te meten?"
- "Overweeg abonnement voor automatische tracking"

**Conversion to subscription:**
- 25% van premium klanten binnen 3 maanden
- Main driver: "We want to track improvements over time"

---

## Journey 3: Abonnement Klant

### Persona: Monitoring Martin
**Profiel:**
- CISO bij enterprise (500+ medewerkers)
- Meerdere Azure tenants
- Maandelijkse compliance rapportage aan board
- Wil geautomatiseerde oplossing

### Reis Stappen

#### 1. Research Phase
**Gebruiker doet:**
- Vergelijkt meerdere compliance tools
- Leest vergelijkingen: premium vs subscription
- Rekent uit ROI: €99/maand vs €299/scan
- Concludeert: subscription = beter voor continue monitoring

**Touchpoint:** Pricing pagina

#### 2. Business Case
**Gebruiker maakt:**
- Cost comparison spreadsheet
- Presentatie voor management
- Berekening: €99 vs €299 = 67% besparing bij maandelijks

**Approval:** Gets budget approval

#### 3. Registration
**Touchpoint:** Subscription registration form

**Gebruiker vult in:**
- Bedrijfsgegevens
- Factuur adres
- Contact personen
- Tenant selectie (kan meerdere tenants toevoegen)
- Preferred scan date (bijv. 1e van maand)

**Emotie:** Professional, committed

#### 4. Subscription Setup
**Touchpoint:** Configuration wizard

**Gebruiker configureert:**
- ISO standaard(en) per tenant
- Email recipients voor rapporten
- Dashboard users (team toegang)
- Invoice details (IBAN, PO nummer)

#### 5. First Scan Scheduling
**Touchpoint:** Calendar interface

**Systeem:**
- Suggests optimal scan date
- Shows next 12 months schedule
- Allows customization per tenant

**Gebruiker:** Confirmeert schema

#### 6. Confirmation & Onboarding
**Touchpoint:** Welcome email + Dashboard access

**Gebruiker ontvangt:**
- Welcome email met:
  - Dashboard login
  - First scan scheduled date
  - Setup checklist
  - Support contact
- Onboarding guide (PDF)
- Video tutorial link

#### 7. First Automated Scan
**Timeline:** Eerste van de maand (zoals geconfigureerd)

**Proces:**
- 🤖 Systeem triggert scan automatisch
- 📧 Email: "Je maandelijkse scan is gestart"
- ⏱️ Processing (fully automated, no user action)
- 📧 Email: "Je rapport is klaar"

**Gebruiker actie:** GEEN - volledig geautomatiseerd

**Emotie:** Satisfaction (hands-off automation)

#### 8. Dashboard Access
**Touchpoint:** Compliance dashboard

**Gebruiker ziet:**
- **Current Score: 72/100** (first scan)
- All findings (20 total)
- Compliance status per control
- Scan history (1 scan so far)
- Next scan date: 30 dagen

**Features:**
- Filter findings by severity
- Export rapport
- Add notes per finding
- Assign remediation tasks (internal)

#### 9. Monthly Routine
**Elke maand:**

**Day 1 (scan dag):**
- 🤖 Automated scan triggers
- 📧 "Scan gestart" notification

**Day 1-2 (processing):**
- No user action required
- System processes in background

**Day 2:**
- 📧 "Rapport klaar" notification
- 📊 Dashboard updates automatically

**Gebruiker reviews:**
- New compliance score: 75/100 (+3! 🎉)
- **Trend indicator: Improving ↗️**
- Comparison met vorige maand:
  - 3 issues resolved ✅
  - 1 new issue ⚠️
  - 2 issues degraded 📉
- Recommendations prioritized by impact

**Emotie:** Satisfaction (zien vooruitgang), Motivation (verder verbeteren)

#### 10. Historical Analysis
**Touchpoint:** Trends pagina in dashboard

**Na 6 maanden:**
- **Score evolution graph:** 72 → 75 → 78 → 80 → 82 → 85
- **Improvement rate:** +13 points in 6 maanden
- **Resolved issues:** 15 van 20 original findings
- **New issues:** 5 (due to new resources)
- **Compliance trend:** Strong improvement 📈

**Value realization:**
- "We kunnen vooruitgang laten zien aan board"
- "Historische data essentieel voor audits"
- "Trends helpen prioriteren wat belangrijk is"

#### 11. Invoice & Payment
**Maandelijks proces:**

**Day 1:**
- Factuur gegenereerd en verstuurd per email
- Bedrag: €119.79 incl. BTW
- Betalingstermijn: 14 dagen
- Factuur details in dashboard

**Day 8:**
- Reminder email (als nog niet betaald)

**Day 14:**
- Payment due

**Day 15+ (indien niet betaald):**
- Automated reminder
- Account status: "Payment overdue"

**Day 30+ (indien nog steeds niet betaald):**
- Account suspended
- No new scans until paid

**Normale flow:**
- SEPA automatische incasso (90% van klanten)
- Handmatige betaling binnen 14 dagen (10%)

#### 12. Expansion
**Na 3 maanden:**

**Gebruiker wil:**
- Extra tenant toevoegen (acquired nieuwe business unit)
- Higher scan frequency (weekly) voor kritieke tenant

**Touchpoint:** Dashboard → "Add tenant" of contact sales

**Upgrade:**
- +€99/maand voor tweede tenant
- Custom pricing voor weekly scans

#### 13. Long-term Value
**Na 12 maanden:**

**Gebruiker heeft:**
- 12 maanden historische data
- Compliance improvement van 72 → 88
- Presentations voor board (exported trends)
- Successful audit met compliance rapporten
- Team trained op platform

**ROI realized:**
- Cost: €1,188 (vs €3,588 voor 12 premium scans)
- Time saved: Geen handmatige scans triggeren
- Value: Historische trends voor audits
- Peace of mind: Automated monitoring

**Retention:** Hoge retention rate (85%+)

**Churn risks:**
- Budget cuts (kan downgraden naar quarterly scans)
- Acquisition (nieuwe moederbedrijf heeft ander tool)
- In-house solution (grote enterprises)

---

## Conversion Funnels

### Free → Premium Conversion

**Touchpoints voor conversie:**
1. **Preview results page** (primary): "Zie alle bevindingen"
2. **Email follow-up** (24u): Case study + 10% discount
3. **Email follow-up** (1 week): "Nog steeds compliance vragen?"
4. **Retargeting ads**: Show resolved issues from others

**Conversion rate:** 20-25% within 30 days

**Keys to success:**
- Show value of hidden findings
- Create FOMO (what are you missing?)
- Provide social proof
- Limited time discount

### Free → Subscription Conversion

**Less common but happens when:**
- Larger organizations (200+ employees)
- Multiple tenants to monitor
- Already convinced of need for continuous monitoring

**Conversion rate:** 5-8% within 30 days

### Premium → Subscription Conversion

**Triggers:**
1. **After 3 months:** "Want to re-scan to track improvements?"
2. **After 6 months:** "Switch to subscription and save 67%"
3. **Multiple scans:** "You've done 3 scans, subscription is cheaper"

**Conversion rate:** 25-30% within 6 months

**Keys to success:**
- Show cost comparison
- Highlight value of trends
- Offer seamless migration (historical data import)
- First month 50% off

---

## Key Metrics per Journey

### Free Scan Journey
- **Sign-up rate:** 35% of landing page visitors
- **Completion rate:** 80% (some drop at Azure OAuth)
- **Upgrade rate:** 20-25% to premium, 5-8% to subscription
- **Time to conversion:** 24-48 hours (median)

### Premium Scan Journey
- **Purchase rate:** 15% of info page visitors
- **Cart abandonment:** 25% (at payment page)
- **Completion rate:** 95% (after payment)
- **Satisfaction score:** 4.5/5
- **Repeat purchase:** 40% within 6 months

### Subscription Journey
- **Trial-to-paid:** N/A (no trial, but free scan can be trial)
- **Onboarding completion:** 95%
- **Monthly active usage:** 90% (check dashboard at least once)
- **Retention rate:** 85% after 12 months
- **Expansion rate:** 30% add additional tenants/features
- **Churn rate:** 5% per month

---

## Optimization Opportunities

### Free Scan
- ✅ Faster scan (currently 3-5 min, target < 2 min)
- ✅ Show more preview (3 findings instead of 2?)
- ✅ Better visualization of hidden value
- ✅ Immediate chat support offer

### Premium Scan
- ✅ Priority processing as default (vs add-on)
- ✅ Live chat during checkout for questions
- ✅ Progress notifications via SMS (opt-in)
- ✅ Interactive report (web-based, not just PDF)

### Subscription
- ✅ Mobile app for dashboard access
- ✅ Slack/Teams integration for notifications
- ✅ Customizable scan frequency per tenant
- ✅ API for custom integrations
- ✅ White-label option for MSPs

---

## Critical User Journey Corrections

### ❌ INCORRECT (Oude informatie)
**"Abonnement geeft 1 gratis scan per maand"**
- Dit suggereert dat gebruiker handmatig gratis scan kan triggeren
- Impliceert unlimite scanning wanneer je maar wilt
- Verwarrend met premium scan proposition

### ✅ CORRECT (Nieuwe informatie)
**"Abonnement geeft 1 geautomatiseerde scan per maand per tenant"**
- Duidelijk: het is automatisch, niet on-demand
- Benadrukt automation value (hands-off)
- Geen verwarring met premium scans
- Extra scans zijn mogelijk maar niet gratis

**Impact op user journey:**
- Expectation management: Users weten wat ze krijgen
- Value proposition: Automation is de waarde, niet "gratis scans"
- Upsell opportunity: Extra scans zijn premium service
- Clear differentiation: Subscription ≠ unlimited premium scans
