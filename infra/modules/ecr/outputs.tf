output "repository_urls" {
    description = "URLs of the created ECR repositories"
    value       = { for key, repo in aws_ecr_repository.repo : key => repo.repository_url }
}

output "registry_url" {
    description = "Base ECR registry URL without the repository name"
    value       = substr(values(aws_ecr_repository.repo)[0].repository_url, 0, length(values(aws_ecr_repository.repo)[0].repository_url) - length(values(aws_ecr_repository.repo)[0].name) - 1)
}

output "repository_arns" {
    description = "ARNs of the created ECR repositories"
    value       = { for key, repo in aws_ecr_repository.repo : key => repo.arn }
}
