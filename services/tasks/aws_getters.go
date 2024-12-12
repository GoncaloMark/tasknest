package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
)

func getParameter(ssmClient *ssm.Client, parameterName string, ctx context.Context) string {
	withDecryption := true
	param, err := ssmClient.GetParameter(ctx, &ssm.GetParameterInput{
		Name:           aws.String(parameterName),
		WithDecryption: &withDecryption,
	})
	if err != nil {
		log.Fatalf("Failed to fetch parameter %s: %v", parameterName, err)
	}
	return aws.ToString(param.Parameter.Value)
}

func getSecretValue(secretsManagerClient *secretsmanager.Client, secretID string, ctx context.Context) ([]byte, error) {
	output, err := secretsManagerClient.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretID),
	})
	if err != nil {
		return nil, fmt.Errorf("unable to retrieve secret %s: %v", secretID, err)
	}

	return []byte(*output.SecretString), nil
}
