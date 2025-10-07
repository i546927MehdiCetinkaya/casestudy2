# ECR Repositories
resource "aws_ecr_repository" "soar_api" {
  name                 = "${var.project_name}/${var.environment}/soar-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-soar-api"
  }
}

resource "aws_ecr_repository" "soar_processor" {
  name                 = "${var.project_name}/${var.environment}/soar-processor"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-soar-processor"
  }
}

resource "aws_ecr_repository" "soar_remediation" {
  name                 = "${var.project_name}/${var.environment}/soar-remediation"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-soar-remediation"
  }
}

# ECR Lifecycle Policies
resource "aws_ecr_lifecycle_policy" "soar_api" {
  repository = aws_ecr_repository.soar_api.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "soar_processor" {
  repository = aws_ecr_repository.soar_processor.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "soar_remediation" {
  repository = aws_ecr_repository.soar_remediation.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
