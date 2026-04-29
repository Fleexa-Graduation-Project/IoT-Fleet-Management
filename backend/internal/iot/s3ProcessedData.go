package iot

import (
	"context"
	"encoding/json"
	"fmt"
	"io"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
    
    // 1. Add the telemetry import so we have access to the struct
	"github.com/Fleexa-Graduation-Project/Backend/internal/telemetry" 
)

type S3Client struct {
	client *s3.Client
	bucket string
}

func NewS3Client(ctx context.Context, bucketName string) (*S3Client, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, fmt.Errorf("unable to load AWS config: %v", err)
	}

	return &S3Client{
		client: s3.NewFromConfig(cfg),
		bucket: bucketName,
	}, nil
}
 //downloads a JSON file from S3 and parses it
func (client *S3Client) GetMonthlyChart(ctx context.Context, key string) ([]telemetry.ChartPoint, error) {
	result, err := client.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(client.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get object from s3 with (Key: %s): %v", key, err)
	}
	defer result.Body.Close()

	body, err := io.ReadAll(result.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read s3 body: %v", err)
	}

	var chartData []telemetry.ChartPoint  
    
	if err := json.Unmarshal(body, &chartData); err != nil {
		return nil, fmt.Errorf("failed to parse s3 JSON: %v", err)
	}

	return chartData, nil
}