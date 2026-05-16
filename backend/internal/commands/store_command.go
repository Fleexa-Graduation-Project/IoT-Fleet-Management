package commands

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"

	"github.com/Fleexa-Graduation-Project/Backend/models"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/db"
)

type CommandStore struct {
	Client    *dynamodb.Client
	TableName string
}

func NewCommandStore() (*CommandStore, error) {
	tableName := os.Getenv("COMMANDS_TABLE")
	if tableName == "" {
		return nil, fmt.Errorf("COMMANDS_TABLE environment variable is not set")
	}

	if db.Client == nil {
		return nil, fmt.Errorf("dynamodb client is not initialized")
	}

	return &CommandStore{
		Client:    db.Client,
		TableName: tableName,
	}, nil
}

func (store *CommandStore) SaveCommand(ctx context.Context, cmd models.Command) error {
	if cmd.ExpiresAt == 0 {
		cmd.ExpiresAt = time.Now().Add(30 * 24 * time.Hour).Unix()
	}

	if cmd.Timestamp == 0 {
		cmd.Timestamp = time.Now().Unix()
	}

	item, err := attributevalue.MarshalMap(cmd)
	if err != nil {
		return fmt.Errorf("failed to marshal command: %w", err)
	}

	//injects composite GSI key for DeviceHistoryIndex (PK=user_device_id, SK=timestamp).
	item["user_device_id"] = &types.AttributeValueMemberS{Value: cmd.UserID + "#" + cmd.DeviceID}

	_, err = store.Client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(store.TableName),
		Item:      item,
	})
	if err != nil {
		return fmt.Errorf("failed to store command: %w", err)
	}

	return nil
}
