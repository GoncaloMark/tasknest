package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	"github.com/aws/aws-sdk-go/service/ssm"
)

func getParameter(ssmClient *ssm.SSM, parameterName string) string {
	withDecryption := true
	param, err := ssmClient.GetParameter(&ssm.GetParameterInput{
		Name:           aws.String(parameterName),
		WithDecryption: &withDecryption,
	})
	if err != nil {
		log.Fatalf("Failed to fetch parameter %s: %v", parameterName, err)
	}
	return aws.StringValue(param.Parameter.Value)
}

func getSecretValue(secretsManagerClient *secretsmanager.SecretsManager, secretID string) (*DBCreds, error) {
	output, err := secretsManagerClient.GetSecretValue(&secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretID),
	})
	if err != nil {
		return nil, fmt.Errorf("unable to retrieve secret %s: %v", secretID, err)
	}

	var creds DBCreds
	if err := json.Unmarshal([]byte(*output.SecretString), &creds); err != nil {
		return nil, fmt.Errorf("unable to parse secret: %v", err)
	}

	return &creds, nil
}
