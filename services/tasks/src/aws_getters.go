package main

import (
	"context"
	"encoding/json"
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

func getSecretValue(secretsManagerClient *secretsmanager.Client, secretID string, ctx context.Context) (*DBCreds, error) {
	output, err := secretsManagerClient.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
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
