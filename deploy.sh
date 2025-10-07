#!/bin/bash

# Case Study 2 Deployment Script
# Author: Mehdi Cetinkaya
# Description: Automated deployment script for SOAR Security Platform

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     SOAR Security Platform - Deployment Script          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Configuration
AWS_REGION="eu-central-1"
ENVIRONMENT="dev"
PROJECT_NAME="casestudy2"
ECR_REGISTRY="920120424621.dkr.ecr.eu-central-1.amazonaws.com"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    command -v aws >/dev/null 2>&1 || { log_error "AWS CLI not found. Please install it."; exit 1; }
    command -v terraform >/dev/null 2>&1 || { log_error "Terraform not found. Please install it."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl not found. Please install it."; exit 1; }
    command -v docker >/dev/null 2>&1 || { log_error "Docker not found. Please install it."; exit 1; }
    
    log_info "All prerequisites met ✓"
}

# Create S3 bucket for Terraform state
create_s3_bucket() {
    log_info "Creating S3 bucket for Terraform state..."
    
    aws s3 mb s3://${PROJECT_NAME}-terraform-state --region ${AWS_REGION} 2>/dev/null || log_warn "Bucket already exists"
    aws s3api put-bucket-versioning \
        --bucket ${PROJECT_NAME}-terraform-state \
        --versioning-configuration Status=Enabled
    
    log_info "S3 bucket configured ✓"
}

# Deploy Terraform infrastructure
deploy_terraform() {
    log_info "Deploying Terraform infrastructure..."
    
    cd terraform
    
    terraform init
    terraform plan -out=tfplan
    terraform apply -auto-approve tfplan
    
    cd ..
    
    log_info "Infrastructure deployed ✓"
}

# Build and push Docker images
build_docker_images() {
    log_info "Building and pushing Docker images..."
    
    # Login to ECR
    aws ecr get-login-password --region ${AWS_REGION} | \
        docker login --username AWS --password-stdin ${ECR_REGISTRY}
    
    # Build and push each service
    for service in soar-api soar-processor soar-remediation; do
        log_info "Building ${service}..."
        cd docker/${service}
        docker build -t ${ECR_REGISTRY}/${PROJECT_NAME}/${ENVIRONMENT}/${service}:latest .
        docker push ${ECR_REGISTRY}/${PROJECT_NAME}/${ENVIRONMENT}/${service}:latest
        cd ../..
        log_info "${service} built and pushed ✓"
    done
}

# Deploy Lambda functions
deploy_lambda() {
    log_info "Deploying Lambda functions..."
    
    for lambda_dir in lambda/*/; do
        lambda_name=$(basename $lambda_dir)
        log_info "Packaging ${lambda_name}..."
        
        cd $lambda_dir
        pip install -r requirements.txt -t . --quiet
        zip -r ${lambda_name}.zip . -x "*.pyc" -x "__pycache__/*" > /dev/null
        
        log_info "Updating Lambda function: ${PROJECT_NAME}-${ENVIRONMENT}-${lambda_name}"
        aws lambda update-function-code \
            --function-name ${PROJECT_NAME}-${ENVIRONMENT}-${lambda_name} \
            --zip-file fileb://${lambda_name}.zip \
            --region ${AWS_REGION} || log_warn "Lambda update failed for ${lambda_name}"
        
        cd ../..
    done
    
    log_info "Lambda functions deployed ✓"
}

# Deploy to EKS
deploy_eks() {
    log_info "Deploying to EKS..."
    
    # Update kubeconfig
    aws eks update-kubeconfig --name ${PROJECT_NAME}-${ENVIRONMENT}-eks --region ${AWS_REGION}
    
    # Apply Kubernetes manifests
    kubectl apply -f kubernetes/namespace.yaml
    kubectl apply -f kubernetes/soar-api-deployment.yaml
    kubectl apply -f kubernetes/soar-processor-deployment.yaml
    kubectl apply -f kubernetes/soar-remediation-deployment.yaml
    kubectl apply -f kubernetes/ingress.yaml
    
    # Deploy monitoring
    kubectl apply -f kubernetes/prometheus.yaml
    kubectl apply -f kubernetes/grafana.yaml
    
    # Wait for deployments
    log_info "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/soar-api -n soar-system
    kubectl wait --for=condition=available --timeout=300s deployment/soar-processor -n soar-system
    kubectl wait --for=condition=available --timeout=300s deployment/soar-remediation -n soar-system
    
    log_info "EKS deployment complete ✓"
}

# Display endpoints
display_endpoints() {
    log_info "Deployment Summary:"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "SOAR API Service:"
    kubectl get svc soar-api -n soar-system
    echo ""
    echo "Application Ingress:"
    kubectl get ingress -n soar-system
    echo ""
    echo "Grafana Dashboard:"
    kubectl get svc grafana -n monitoring
    echo "═══════════════════════════════════════════════════════════"
}

# Main deployment flow
main() {
    log_info "Starting deployment process..."
    echo ""
    
    check_prerequisites
    create_s3_bucket
    deploy_terraform
    build_docker_images
    deploy_lambda
    deploy_eks
    display_endpoints
    
    echo ""
    log_info "🎉 Deployment completed successfully!"
    echo ""
    log_info "Access Grafana: kubectl port-forward svc/grafana 3000:80 -n monitoring"
    log_info "View logs: kubectl logs -f deployment/soar-api -n soar-system"
}

# Run main function
main
