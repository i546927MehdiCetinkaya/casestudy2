# ⚠️ SNELLE AWS CLEANUP CHECKLIST

## Situatie
Terraform state is corrupt door incomplete destroy. We moeten ALLES handmatig verwijderen in AWS Console.

## 🎯 PRIORITEIT: Verwijder deze 5 dingen EERST

### 1. Lambda Event Source Mappings (5 min)
**WHY:** Blokkeren Lambda en SQS verwijdering
**WHERE:** https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1#/functions

Voor ELKE Lambda function:
- [ ] casestudy2-dev-parser → Configuration → Triggers → Delete ALL triggers
- [ ] casestudy2-dev-engine → Configuration → Triggers → Delete ALL triggers  
- [ ] casestudy2-dev-notify → Configuration → Triggers → Delete ALL triggers
- [ ] casestudy2-dev-remediate → Configuration → Triggers → Delete ALL triggers

### 2. EKS Cluster (15 min wachttijd)
**WHY:** Langste delete tijd, start nu
**WHERE:** https://eu-central-1.console.aws.amazon.com/eks/home?region=eu-central-1#/clusters

- [ ] Find: `casestudy2-dev-eks`
- [ ] Click cluster name → Delete → Type cluster name → Delete
- [ ] ⏳ WAIT 15 minutes (don't close window)

### 3. Load Balancer + Target Groups (2 min)
**WHY:** Blokkeren VPC verwijdering
**WHERE:** https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#LoadBalancers:

**Load Balancers:**
- [ ] Find: `casestudy2-dev-alb`
- [ ] Select → Actions → Delete

**Target Groups:**
- [ ] Go to: https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#TargetGroups:
- [ ] Find: `casestudy2-dev-*`
- [ ] Select ALL → Actions → Delete

### 4. NAT Gateways (5 min)
**WHY:** Kosten geld per uur + blokkeren subnet delete
**WHERE:** https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1#NatGateways:

- [ ] Find: `casestudy2-dev-*`
- [ ] Select ALL → Actions → Delete NAT Gateway
- [ ] ⏳ Wait 5 minutes for "Deleted" status

### 5. Lambda Functions (1 min)
**WHY:** Na triggers weg, kunnen Lambdas weg
**WHERE:** https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1#/functions

- [ ] casestudy2-dev-parser → Actions → Delete
- [ ] casestudy2-dev-engine → Actions → Delete
- [ ] casestudy2-dev-notify → Actions → Delete
- [ ] casestudy2-dev-remediate → Actions → Delete

---

## ✅ CHECKLIST VOLTOOID?

Als alle 5 stappen klaar zijn, zeg "klaar" en ik maak een fresh deployment!

## ⚡ SNELLE LINKS

- Lambda: https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1
- EKS: https://eu-central-1.console.aws.amazon.com/eks/home?region=eu-central-1
- Load Balancers: https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#LoadBalancers:
- NAT Gateways: https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1#NatGateways:
- VPC: https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1#vpcs:

## 💡 TIP
Open elk tabblad in nieuwe tab (Ctrl+Click) en werk van boven naar beneden.
