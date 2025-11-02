# Frontend Requirements - Cloud Compliance Scanning Platform

## Overview

Dit document beschrijft de frontend requirements voor het cloud compliance scanning platform met focus op de drie service modellen.

## User Interface Requirements

### 1. Landing Page

**Doel:** Presentatie van de drie service opties en waarde propositie

**Elementen:**
- Hero sectie met duidelijke USP
- Drie service cards (Gratis, Premium, Abonnement)
- Pricing tabel
- CTA buttons voor elke service
- Social proof (testimonials, logos)

**Key Messaging:**
- "Controleer uw Azure compliance in minuten"
- Duidelijk onderscheid tussen de drie services
- Transparante pricing

### 2. Gratis Scan Flow

**Pagina's:**
1. **Service selectie**
   - Keuze tussen ISO 27017 en ISO 27018
   - Uitleg van elk standaard
   - "Start gratis scan" button

2. **Azure autorisatie**
   - Azure OAuth consent screen
   - Uitleg welke permissies gevraagd worden
   - Privacy informatie

3. **Scan in progress**
   - Loading indicator met voortgang
   - Geschatte tijd (2-5 minuten)
   - Wat er gebeurt uitleg

4. **Resultaten (preview)**
   - **Maximaal 2 bevindingen tonen**
   - Compliance score (verborgen details)
   - "Upgrade voor volledig rapport" CTA
   - Preview van grijze/verborgen findings
   - Vergelijking free vs premium features

**Belangrijke UI elementen:**
- Duidelijk label "Gratis Scan Preview"
- Visueel onderscheid tussen zichtbare en verborgen findings
- Overtuigende upgrade CTA's
- "Meer bevindingen beschikbaar in premium versie" indicator

### 3. Premium Scan Flow

**Pagina's:**
1. **Service overzicht**
   - Uitleg van premium features
   - Pricing informatie
   - FAQ sectie

2. **Document upload**
   - Drag & drop interface
   - Multiple file upload (PDF, DOCX, TXT)
   - Max 50MB per document
   - Progress indicators
   - File preview/management

3. **ISO standaard selectie**
   - Radio buttons voor ISO 27017 / ISO 27018
   - Uitleg van verschillen
   - Recommended option based op tenant type

4. **Betaling**
   - Stripe/Mollie integration
   - Verschillende betaalmethoden:
     - Credit card (Stripe)
     - iDEAL (Mollie)
     - SEPA (Mollie)
   - Secure payment badge
   - Order overzicht
   - BTW berekening

5. **Azure autorisatie**
   - Pas na succesvolle betaling
   - OAuth flow
   - Permissions uitleg

6. **Scan processing**
   - Extended progress indicator (15-30 min)
   - Status updates:
     - Document parsing
     - Tenant analysis
     - AI processing
     - Report generation
   - Email notificatie wanneer klaar

7. **Volledig rapport**
   - Executive summary
   - Compliance score per control
   - Alle bevindingen met details:
     - Severity indicator
     - Current state
     - Required state
     - Remediation advice
     - Risk score
   - Export opties (PDF, Excel)
   - Print-friendly view

**UI/UX Focus:**
- Vertrouwen opbouwen bij betaling
- Transparantie over proces
- Professionele rapportage presentatie
- Actionable insights

### 4. Abonnement Flow

**Pagina's:**
1. **Abonnement overzicht**
   - Features lijst:
     - **€99 per maand**
     - **1 geautomatiseerde scan per maand per tenant**
     - Historische trenddata
     - Compliance dashboard
     - Priority support
   - **GEEN vermelding van "gratis scan"**
   - Correcte tekst: "1 automatische scan per maand inclusief"

2. **Registratie**
   - Bedrijfsgegevens formulier
   - Tenant selectie
   - Factuur gegevens (IBAN voor SEPA)
   - Algemene voorwaarden acceptatie

3. **Bevestiging**
   - Overzicht van abonnement
   - Factuur informatie
   - "Factuur met 14 dagen betalingstermijn"
   - Eerste scan planning

4. **Compliance Dashboard** (voor abonnees)
   - **Hoofdscherm:**
     - Huidige compliance score
     - Trend grafiek (maandelijks)
     - Laatste scan datum
     - Volgende scan datum
     - Status indicators
   
   - **Historische data:**
     - Timeline van alle scans
     - Score evolutie grafiek
     - Vergelijking tussen scans
     - Improvement/degradation indicators
   
   - **Bevindingen overzicht:**
     - Actieve issues
     - Opgeloste issues
     - Nieuwe issues sinds laatste scan
     - Priority matrix
   
   - **Rapporten archief:**
     - Alle eerdere scan rapporten
     - Download mogelijkheden
     - Vergelijkings functie

5. **Facturatie sectie**
   - Overzicht van facturen
   - Status (betaald, open, te laat)
   - Betalingshistorie
   - Download facturen
   - Betaal optie voor openstaande facturen

**Belangrijke UI messaging:**
- ✅ "1 geautomatiseerde scan per maand per tenant"
- ✅ "Automatische rapportage elke maand"
- ✅ "Historische compliance tracking"
- ❌ NIET: "1 gratis scan per maand"
- ❌ NIET: "Inclusief gratis handmatige scans"

### 5. Navigatie & Layout

**Header:**
- Logo
- Navigatie menu:
  - Services
  - Pricing
  - Documentation
  - Login/Dashboard
- CTA button "Start scan"

**Footer:**
- Links naar documentatie
- Contact informatie
- Privacy & Terms
- Social media
- Trust badges (ISO certified, GDPR compliant)

## Component Library

### Reusable Components

1. **ServiceCard**
   - Props: title, price, features, cta, highlighted
   - Variant: free, premium, subscription

2. **ComplianceScoreDisplay**
   - Visual gauge/chart
   - Color coding (red, orange, green)
   - Tooltip met uitleg

3. **FindingCard**
   - Severity badge
   - Title en description
   - Collapsible details
   - Remediation advice section

4. **ProgressIndicator**
   - Multi-step indicator
   - Current step highlight
   - Estimated time remaining

5. **DocumentUploader**
   - Drag & drop zone
   - File list met delete optie
   - Upload progress
   - Validation feedback

6. **PricingTable**
   - Comparison tussen services
   - Highlight recommended option
   - Feature checkmarks
   - CTA buttons

## Responsive Design

- Mobile-first approach
- Breakpoints:
  - Mobile: < 768px
  - Tablet: 768px - 1024px
  - Desktop: > 1024px
- Touch-friendly controls
- Optimized for iOS en Android

## Accessibility

- WCAG 2.1 AA compliance
- Keyboard navigation
- Screen reader support
- Color contrast requirements
- Alt text voor images
- ARIA labels

## Performance

- Lazy loading van components
- Optimized images (WebP, responsive)
- Code splitting per route
- CDN voor static assets
- < 3s initial load time
- < 1s route transitions

## Browser Support

- Chrome (laatste 2 versies)
- Firefox (laatste 2 versies)
- Safari (laatste 2 versies)
- Edge (laatste 2 versies)
- Geen IE11 support

## Internationalization

- Primaire taal: Nederlands
- Toekomstige support: Engels
- Date/time formatting (NL)
- Currency: EUR (€)

## Key User Journeys

### Journey 1: Gratis Scan Gebruiker → Premium Conversie

```
Landing → Gratis Scan Start → ISO Selectie → Azure Auth → Scan → 
Preview Results (2 findings) → Upgrade CTA → Premium Purchase → 
Full Report
```

**Conversion touchpoints:**
- Preview results page (primary)
- Email follow-up (secondary)
- Retargeting ads (tertiary)

### Journey 2: Direct Premium Scan

```
Landing → Premium Info → Document Upload → ISO Selectie → 
Payment → Azure Auth → Processing → Email Notification → 
Full Report Download
```

**Trust builders:**
- Social proof bij payment
- Secure payment badges
- Process transparency
- Email updates

### Journey 3: Abonnement Registratie → Dashboard Gebruik

```
Landing → Subscription Info → Registration → Invoice Details → 
Confirmation → First Scan Scheduled → Dashboard Access → 
Monthly Automated Scans → Trend Analysis
```

**Retention features:**
- Maandelijkse email reminders
- Dashboard notifications
- Comparison met previous scans
- Actionable insights

## Error Handling

### Error States
- Network errors
- Payment failures
- Upload errors
- Authentication failures
- Scan timeouts

### User Feedback
- Toast notifications voor quick feedback
- Inline validation voor forms
- Error messages met actionable advice
- Retry mechanisms

## Analytics & Tracking

### Key Metrics
- Conversion rate per service type
- Upgrade rate (free → premium/subscription)
- Time to completion per flow
- Drop-off points
- Feature usage

### Events to Track
- Service selection
- Scan initiated
- Payment completed
- Report downloaded
- Upgrade clicked
- Document uploaded

## Security

- HTTPS only
- Secure storage van credentials
- No sensitive data in localStorage
- XSS protection
- CSRF tokens
- Rate limiting op API calls

## Content Strategy

### Tone of Voice
- Professional maar approachable
- Technisch accuraat maar begrijpelijk
- Actie-georiënteerd
- Vertrouwen-opbouwend

### Key Messages

**Voor Gratis Scan:**
- "Krijg direct inzicht in uw compliance status"
- "Geen creditcard vereist"
- "Binnen 5 minuten resultaten"

**Voor Premium Scan:**
- "Volledige compliance analyse met AI"
- "Concrete remediatie adviezen"
- "Exporteerbare rapporten"

**Voor Abonnement:**
- "Maandelijkse geautomatiseerde compliance monitoring"
- "€99 per maand voor continue inzicht"
- "Track uw compliance trends over tijd"
- "1 automatische scan per maand per tenant"

### Critical Corrections

**VEROUDERD (incorrect):**
- ❌ "1 gratis scan per maand bij abonnement"
- ❌ "Inclusief gratis scans"
- ❌ "Onbeperkt scannen met abonnement"

**CORRECT (volgens businessplan):**
- ✅ "1 geautomatiseerde scan per maand per tenant"
- ✅ "Maandelijkse automatische rapportage"
- ✅ "Extra scans apart aan te schaffen"
- ✅ "Abonnement omvat 1 automatic scan per maand"

## Development Stack (Recommended)

- **Framework:** React of Vue.js
- **Styling:** Tailwind CSS
- **State Management:** Redux of Vuex
- **Forms:** React Hook Form of Vuelidate
- **API Client:** Axios
- **Charts:** Chart.js of Recharts
- **Payment:** Stripe.js + Mollie SDK
- **Auth:** Azure MSAL library

## Testing Requirements

- Unit tests voor alle components
- Integration tests voor flows
- E2E tests voor critical paths
- Visual regression tests
- Cross-browser testing
- Mobile device testing
- Accessibility testing

## Deployment

- CI/CD pipeline
- Staging environment
- Blue-green deployment
- Feature flags voor A/B testing
- CDN caching strategy
- Monitoring (Sentry, DataDog)
