# INFRA

To apply this you need your aws credentials on a profile in .aws/credentials.

Run:

```bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

Push the frontend and backend images to the ECR (check commands on the ECR Dashboard).

To destroy the services:

```bash
terraform destroy -auto-approve
```
