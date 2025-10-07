# GitHub OIDC Setup - Manual Steps via AWS Console

## Step 1: Create OIDC Identity Provider

1. Go to IAM Console: https://console.aws.amazon.com/iam/
2. Click "Identity providers" in the left menu
3. Click "Add provider"
4. Select "OpenID Connect"
5. Configure:
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
6. Click "Get thumbprint" and then "Add provider"

## Step 2: Create or Update IAM Role

### If role doesn't exist:
1. Go to IAM → Roles
2. Click "Create role"
3. Select "Web identity"
4. Choose:
   - Identity provider: `token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
5. Add condition:
   - Key: `token.actions.githubusercontent.com:sub`
   - Condition: `StringLike`
   - Value: `repo:i546927MehdiCetinkaya/casestudy2:*`
6. Click Next
7. Attach policy: `AdministratorAccess` (or create custom policy)
8. Name the role: `githubrepo`
9. Create role

### If role exists:
1. Go to IAM → Roles
2. Search for `githubrepo`
3. Click on the role
4. Go to "Trust relationships" tab
5. Click "Edit trust policy"
6. Replace with this JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::920120424621:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:i546927MehdiCetinkaya/casestudy2:*"
      }
    }
  }]
}
```

7. Click "Update policy"

## Step 3: Verify Role ARN

Make sure the role ARN is exactly:
```
arn:aws:iam::920120424621:role/githubrepo
```

## Step 4: Test the Configuration

1. Go to GitHub repository
2. Navigate to Actions tab
3. Manually trigger the "Deploy to Dev" workflow
4. Check the logs to verify OIDC authentication works

## Troubleshooting

If you still get errors:

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"
- Check that the OIDC provider exists
- Verify the trust policy includes your repository path
- Make sure the condition uses `StringLike` for the `sub` claim

### Error: "No OIDC provider found"
- Create the OIDC provider first (Step 1)
- Wait a few minutes for AWS to propagate the changes

### Error: "Invalid identity token"
- Check that audience is set to `sts.amazonaws.com`
- Verify the provider URL is correct

## Required Permissions

The IAM role needs these permissions at minimum:
- EC2: Full access (for VPC, EKS)
- EKS: Full access
- Lambda: Full access
- DynamoDB: Full access
- RDS: Full access
- SQS: Full access
- SNS: Full access
- EventBridge: Full access
- ECR: Full access
- IAM: Create roles and policies
- CloudWatch: Logs access
- Secrets Manager: Full access

For simplicity during development, you can use `AdministratorAccess` policy.
For production, create a custom policy with only required permissions.
