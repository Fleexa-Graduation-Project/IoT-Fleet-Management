package alerts

import (
	"context"
	"fmt"
	"os"
	"time"
	"github.com/google/uuid"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"

	"github.com/Fleexa-Graduation-Project/Backend/models"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/db"
)

type AlertStore struct {
	Client    *dynamodb.Client
	TableName string
}

func NewAlertStore() (*AlertStore, error) {
	tableName := os.Getenv("ALERTS_TABLE")
	if tableName == "" {
		return nil, fmt.Errorf("ALERTS_TABLE environment variable is not set")
	}

	if db.Client == nil {
		return nil, fmt.Errorf("dynamodb client is not initialized")
	}

	return &AlertStore{
		Client:    db.Client,
		TableName: tableName,
	}, nil
}

//constructing the composite DynamoDB PK for Fleexa_Alerts (userid#deviceid)
func buildUserDeviceKey(userID, deviceID string) string {
	return userID + "#" + deviceID
}

func (store *AlertStore) SaveAlert(ctx context.Context, alert models.Alert) error {
	if alert.AlertID == "" {
		 alert.AlertID = uuid.NewString()
	}
	if alert.ExpiresAt == 0 {
		alert.ExpiresAt = time.Now().Add(30 * 24 * time.Hour).Unix()
	}

	item, err := attributevalue.MarshalMap(alert)
	if err != nil {
		return fmt.Errorf("failed to marshal alert: %w", err)
	}

	//injects composite PK — Fleexa_Alerts PK attribute is user_device_id.
	item["user_device_id"] = &types.AttributeValueMemberS{Value: buildUserDeviceKey(alert.UserID, alert.DeviceID)}

	_, err = store.Client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(store.TableName),
		Item:      item,
	})
	if err != nil {
		return fmt.Errorf("failed to store alert: %w", err)
	}

	return nil
}

//return recent alerts for a specific device
func (store *AlertStore) GetAlertsByDevice(ctx context.Context, userID, deviceID string, limit int32) ([]models.Alert, error) {
	const defaultLimit int32 = 20
	if limit <= 0 {
		limit = defaultLimit
	}

	input := &dynamodb.QueryInput{
		TableName:              aws.String(store.TableName),
		KeyConditionExpression: aws.String("user_device_id = :key"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":key": &types.AttributeValueMemberS{Value: buildUserDeviceKey(userID, deviceID)},
		},
		ScanIndexForward: aws.Bool(false),
		Limit:            aws.Int32(limit),
	}

	res, err := store.Client.Query(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to query alerts user_id=%s device_id=%s: %w", userID, deviceID, err)
	}

	var alertList []models.Alert
	if err = attributevalue.UnmarshalListOfMaps(res.Items, &alertList); err != nil {
		return nil, fmt.Errorf("failed to unmarshal alerts user_id=%s device_id=%s: %w", userID, deviceID, err)
	}

	return alertList, nil
}

//retrieves all alerts for a user in the whole system(system overview part)
func (store *AlertStore) GetAllAlerts(ctx context.Context, userID string, since int64) ([]models.Alert, error) {
	input := &dynamodb.QueryInput{
		TableName:              aws.String(store.TableName),
		IndexName:              aws.String("UserAlertsIndex"),
		KeyConditionExpression: aws.String("user_id = :uid AND #ts >= :since"),
		ExpressionAttributeNames: map[string]string{
			"#ts": "timestamp",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":uid":   &types.AttributeValueMemberS{Value: userID},
			":since": &types.AttributeValueMemberN{Value: fmt.Sprint(since)},
		},
		ScanIndexForward: aws.Bool(false),
	}

	res, err := store.Client.Query(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to query alerts by user user_id=%s: %w", userID, err)
	}

	var alerts []models.Alert
	if err = attributevalue.UnmarshalListOfMaps(res.Items, &alerts); err != nil {
		return nil, fmt.Errorf("failed to unmarshal alerts user_id=%s: %w", userID, err)
	}

	return alerts, nil
}

//filters a user's alerts by severity
func (store *AlertStore) GetAlertsBySeverity(ctx context.Context, userID, severity string, limit int32) ([]models.Alert, error) {
	const defaultLimit int32 = 20
	if limit <= 0 {
		limit = defaultLimit
	}

	input := &dynamodb.QueryInput{
		TableName:              aws.String(store.TableName),
		IndexName:              aws.String("UserAlertsIndex"),
		KeyConditionExpression: aws.String("user_id = :uid"),
		FilterExpression:       aws.String("severity = :sev"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":uid": &types.AttributeValueMemberS{Value: userID},
			":sev": &types.AttributeValueMemberS{Value: severity},
		},
		ScanIndexForward: aws.Bool(false), //newest first
		Limit:            aws.Int32(limit),
	}

	res, err := store.Client.Query(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to query alerts by severity user_id=%s severity=%s: %w", userID, severity, err)
	}

	var alerts []models.Alert
	if err = attributevalue.UnmarshalListOfMaps(res.Items, &alerts); err != nil {
		return nil, fmt.Errorf("failed to unmarshal alerts user_id=%s: %w", userID, err)
	}

	return alerts, nil
}
