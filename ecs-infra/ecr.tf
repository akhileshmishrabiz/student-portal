resource "aws_ecr_repository" "flask_app" {
  # checkov:skip=CKV_AWS_136: dont want kms key
  name = "${var.prefix}-${var.environment}-${var.app_name}"
  
}
