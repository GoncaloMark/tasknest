.PHONY: destroy locals

destroy:
	aws ecr delete-repository --repository-name authorizer-repo --force
	aws ecr delete-repository --repository-name frontend-repo --force
	aws ecr delete-repository --repository-name tasks-repo --force
	aws ecr delete-repository --repository-name users-repo --force
	aws ecr delete-repository --repository-name migrations-repo --force
	aws secretsmanager delete-secret --secret-id cognitoSecret --force-delete-without-recovery
	terraform destroy -auto-approve

REACT_APP_COGNITO_UI := $(shell aws ssm get-parameter --name "/cognito_ui" --query "Parameter.Value" --output text)
REACT_APP_COGNITO_LOGOUT := $(shell aws ssm get-parameter --name "/cognito_logout" --query "Parameter.Value" --output text)

locals:
	docker build --build-arg REACT_APP_COGNITO_UI="$(REACT_APP_COGNITO_UI)" --build-arg REACT_APP_COGNITO_LOGOUT="$(REACT_APP_COGNITO_LOGOUT)" -t frontend-repo ../fe
	docker tag frontend-repo:latest 908776941646.dkr.ecr.us-east-1.amazonaws.com/frontend-repo:latest
	docker push 908776941646.dkr.ecr.us-east-1.amazonaws.com/frontend-repo:latest
	docker build -t tasks-repo ../services/tasks
	docker tag tasks-repo:latest 908776941646.dkr.ecr.us-east-1.amazonaws.com/tasks-repo:latest
	docker push 908776941646.dkr.ecr.us-east-1.amazonaws.com/tasks-repo:latest
	docker build -t users-repo ../services/users
	docker tag users-repo:latest 908776941646.dkr.ecr.us-east-1.amazonaws.com/users-repo:latest
	docker push 908776941646.dkr.ecr.us-east-1.amazonaws.com/users-repo:latest