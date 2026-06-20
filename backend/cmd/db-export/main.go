package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type Exporter struct {
	dynamo *dynamodb.Client
	s3     *s3.Client
	bucket string
}

func main() {
	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		panic(fmt.Sprintf("failed to load aws config: %v", err))
	}

	exporter := &Exporter{
		dynamo: dynamodb.NewFromConfig(cfg),
		s3:     s3.NewFromConfig(cfg),
		bucket: os.Getenv("BUCKET_NAME"),
	}

	lambda.Start(exporter.handler)
}

func (e *Exporter) handler(ctx context.Context, event events.CloudWatchEvent) error {
	tablesEnv := os.Getenv("TABLES_TO_EXPORT")
	if tablesEnv == "" {
		fmt.Println("No tables configured to export.")
		return nil
	}

	tables := strings.Split(tablesEnv, ",")
	timestamp := time.Now().UTC().Format("2006-01-02T15-04-05")

	for _, table := range tables {
		table = strings.TrimSpace(table)
		if table == "" {
			continue
		}

		fmt.Printf("Exporting table: %s\n", table)

		var items []map[string]interface{}
		paginator := dynamodb.NewScanPaginator(e.dynamo, &dynamodb.ScanInput{
			TableName: aws.String(table),
		})

		for paginator.HasMorePages() {
			page, err := paginator.NextPage(ctx)
			if err != nil {
				return fmt.Errorf("failed to scan table %s: %w", table, err)
			}

			var pageItems []map[string]interface{}
			if err := attributevalue.UnmarshalListOfMaps(page.Items, &pageItems); err != nil {
				return fmt.Errorf("failed to unmarshal dynamo items: %w", err)
			}
			items = append(items, pageItems...)
		}

		if len(items) == 0 {
			fmt.Printf("Table %s is empty, skipping export.\n", table)
			continue
		}

		// Convert to JSON
		jsonData, err := json.MarshalIndent(items, "", "  ")
		if err != nil {
			return fmt.Errorf("failed to marshal items to json: %w", err)
		}

		// Upload to S3
		key := fmt.Sprintf("exports/%s/%s/%s.json", time.Now().Format("2006-01-02"), table, timestamp)

		_, err = e.s3.PutObject(ctx, &s3.PutObjectInput{
			Bucket:      aws.String(e.bucket),
			Key:         aws.String(key),
			Body:        bytes.NewReader(jsonData),
			ContentType: aws.String("application/json"),
		})

		if err != nil {
			return fmt.Errorf("failed to upload export to s3 for %s: %w", table, err)
		}

		fmt.Printf("Successfully exported %d items to s3://%s/%s\n", len(items), e.bucket, key)
	}

	return nil
}
