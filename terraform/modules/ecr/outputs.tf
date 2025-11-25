output "ecr_repository_name" {
  value = aws_ecr_repository.ecr_repo.name
}

output "ecr_repository_arn" {
  value = aws_ecr_repository.ecr_repo.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.ecr_repo.repository_url
}
