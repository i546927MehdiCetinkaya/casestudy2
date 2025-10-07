#!/bin/bash
# Script to cleanup ECR repositories before destroy

set -e

REGION="eu-central-1"
REPOS=(
  "casestudy2/dev/soar-api"
  "casestudy2/dev/soar-processor"
  "casestudy2/dev/soar-remediation"
)

echo "🧹 Cleaning up ECR repositories..."

for REPO in "${REPOS[@]}"; do
  echo "Checking repository: $REPO"
  
  # Get all image IDs
  IMAGE_IDS=$(aws ecr list-images --repository-name "$REPO" --region "$REGION" --query 'imageIds[*]' --output json 2>/dev/null || echo "[]")
  
  if [ "$IMAGE_IDS" != "[]" ]; then
    echo "Deleting images from $REPO..."
    aws ecr batch-delete-image \
      --repository-name "$REPO" \
      --region "$REGION" \
      --image-ids "$IMAGE_IDS" || true
    echo "✅ Images deleted from $REPO"
  else
    echo "⚠️  Repository $REPO is empty or doesn't exist"
  fi
done

echo "✅ ECR cleanup complete!"
