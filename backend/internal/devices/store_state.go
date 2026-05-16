package devices

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"

	"github.com/Fleexa-Graduation-Project/Backend/models"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/db"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
)

const (
	OfflineLimit = 2 * time.Minute
)

type StateStore struct {
	Client    *dynamodb.Client
	TableName string
}

func NewStateStore() (*StateStore, error) {
	tableName := os.Getenv("STATE_TABLE")
	if tableName == "" {
		return nil, fmt.Errorf("STATE_TABLE environment variable is not set")
	}

	if db.Client == nil {
		return nil, fmt.Errorf("dynamodb client not initialized")
	}

	return &StateStore{
		Client:    db.Client,
		TableName: tableName,
	}, nil
}

//updates live dashboard
func (s *StateStore) UpdateFromTelemetry(ctx context.Context, tel models.Telemetry) error {

	now := time.Now().Unix()

	opState, health := ExtractState(tel.Type, tel.Payload)
	status := "ONLINE"
	payload, err := attributevalue.Marshal(tel.Payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String(s.TableName),
		Key: map[string]types.AttributeValue{
			"user_id":   &types.AttributeValueMemberS{
				Value: tel.UserID},
			"device_id": &types.AttributeValueMemberS{
				Value: tel.DeviceID,
			},
		},
		ConditionExpression: aws.String(
			"attribute_not_exists(last_seen_at) OR last_seen_at <= :last_seen",
		),
		UpdateExpression: aws.String(`
			SET
				#type = :type,
				#status = :status,
				operational_state = :op_state,
				health = :health,
				payload = :payload,
				last_seen_at = :last_seen,
				updated_at = :updated_at
		`),
		ExpressionAttributeNames: map[string]string{
			"#type":   "type",
			"#status": "status",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":type":       &types.AttributeValueMemberS{Value: tel.Type},
			":status":     &types.AttributeValueMemberS{Value: status},
			":op_state":   &types.AttributeValueMemberS{Value: opState},
			":health":     &types.AttributeValueMemberS{Value: health},
			":payload":    payload, //stores payload map(temp, gas_level, etc.)
			":last_seen":  &types.AttributeValueMemberN{Value: fmt.Sprint(tel.Timestamp)},
			":updated_at": &types.AttributeValueMemberN{Value: fmt.Sprint(now)},
		},
	}

	_, err = s.Client.UpdateItem(ctx, input)
	if err != nil {
		return fmt.Errorf("failed to update device state: %w", err)
	}

	return nil
}



//extracting op state and health from the device type and its payload
func ExtractState(deviceType string, payload map[string]interface{}) (string, string) {

	deviceRules, ok := Rules[deviceType]
	opState := "UNKNOWN"
	health := "DEGRADED"

	if ok {
		opState = deviceRules.ExtractOperational(payload)
		health = deviceRules.EvaluateHealth(opState)
	}

	return opState, health
}

//marks the device online for alert-type messages.
func (s *StateStore) UpdateHeartbeat(ctx context.Context, userID, deviceID string) error {
	now := time.Now().Unix()

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String(s.TableName),
		Key: map[string]types.AttributeValue{
			"user_id":   &types.AttributeValueMemberS{Value: userID},
			"device_id": &types.AttributeValueMemberS{Value: deviceID},
		},
		ConditionExpression: aws.String(
			"attribute_not_exists(last_seen_at) OR last_seen_at <= :last_seen",
		),
		UpdateExpression: aws.String(
			"SET #status = :status, last_seen_at = :last_seen",
		),
		ExpressionAttributeNames: map[string]string{
			"#status": "status",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":status":    &types.AttributeValueMemberS{Value: "ONLINE"},
			":last_seen": &types.AttributeValueMemberN{Value: fmt.Sprint(now)},
		},
	}

	_, err := s.Client.UpdateItem(ctx, input)
	return err
}

func ConnectionStatus(lastSeenAt int64) string {
	if time.Since(time.Unix(lastSeenAt, 0)) > OfflineLimit {
		return "OFFLINE"
	}
	return "ONLINE"
}

// retrieve all devices states for the dashboard
func (store *StateStore) GetAllStates(ctx context.Context, userID string) ([]models.DeviceState, error) {
	var states []models.DeviceState
	var lastEvaluatedKey map[string]types.AttributeValue

	// Keep scanning until we get all devices
	for {
		input := &dynamodb.QueryInput{
			TableName:              aws.String(store.TableName),
			KeyConditionExpression: aws.String("user_id = :uid"),
			ExpressionAttributeValues: map[string]types.AttributeValue{
				":uid": &types.AttributeValueMemberS{Value: userID},
			},
			ExclusiveStartKey: lastEvaluatedKey, // Start where the last page left off
		}

		result, err := store.Client.Query(ctx, input) // works as select * w/o WHERE clause
		if err != nil {
			return nil, fmt.Errorf("failed to query devices for user %s: %w", userID, err)
		}

		for _, item := range result.Items {
			var state models.DeviceState
			if err := attributevalue.UnmarshalMap(item, &state); err != nil {
				fmt.Printf("Warning: failed to unmarshal device state: %v\n", err)
				continue
			}
			states = append(states, state)
		}
		lastEvaluatedKey = result.LastEvaluatedKey
		if lastEvaluatedKey == nil {
			break
		}
	}

	return states, nil
}



func (store *StateStore) GetAllOpenDoors(ctx context.Context) ([]models.DeviceState, error) {
	var states []models.DeviceState
	var lastEvaluatedKey map[string]types.AttributeValue

	
	for {
		input := &dynamodb.QueryInput{
			TableName:              aws.String(store.TableName),
			IndexName:              aws.String("OpenDoorsIndex"),
			KeyConditionExpression: aws.String("operational_state = :open"),
			ExpressionAttributeValues: map[string]types.AttributeValue{
				":open": &types.AttributeValueMemberS{Value: "OPEN"},
			},
			ExclusiveStartKey: lastEvaluatedKey,
		}

		result, err := store.Client.Query(ctx, input)
		if err != nil {
			return nil, fmt.Errorf("failed to query OpenDoorsIndex: %w", err)
		}

		for _, item := range result.Items {
			var state models.DeviceState
			if err := attributevalue.UnmarshalMap(item, &state); err != nil {
				continue
			}
			states = append(states, state)
		}

		lastEvaluatedKey = result.LastEvaluatedKey
		if lastEvaluatedKey == nil {
			break
		}
	}

	return states, nil
}

// retrieve the device state by id
func (s *StateStore) GetStateByID(ctx context.Context, userID, deviceID string) (*models.DeviceState, error) {
	input := &dynamodb.GetItemInput{
		TableName: aws.String(s.TableName),
		Key: map[string]types.AttributeValue{
			"user_id":   &types.AttributeValueMemberS{Value: userID},
			"device_id": &types.AttributeValueMemberS{Value: deviceID},
		},
	}

	result, err := s.Client.GetItem(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to get device state user_id=%s device_id=%s: %w", userID, deviceID, err)
	}

	// If the device doesn't exist, return an empty item map
	if result.Item == nil {
		return nil, nil
	}

	var state models.DeviceState
	if err := attributevalue.UnmarshalMap(result.Item, &state); err != nil {
		return nil, fmt.Errorf("failed to unmarshal device state: %w", err)
	}

	return &state, nil
}