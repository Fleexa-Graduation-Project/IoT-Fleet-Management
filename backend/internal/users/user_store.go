package users

import (
	"context"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"

	"github.com/Fleexa-Graduation-Project/Backend/models"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/db"
)

type UserStore struct {
	Client    *dynamodb.Client
	TableName string
}

func NewUserStore() (*UserStore, error) {
	tableName := os.Getenv("USERS_TABLE")
	if tableName == "" {
		return nil, fmt.Errorf("USERS_TABLE environment variable is not set")
	}
	if db.Client == nil {
		return nil, fmt.Errorf("dynamodb client is not initialized")
	}
	return &UserStore{Client: db.Client, TableName: tableName}, nil
}

//returns the stored profile for userID, or a safe default
func (s *UserStore) GetUserProfile(ctx context.Context, userID string) (models.UserProfile, error) {
	input := &dynamodb.GetItemInput{
		TableName: aws.String(s.TableName),
		Key: map[string]types.AttributeValue{
			"user_id": &types.AttributeValueMemberS{Value: userID},
		},
	}

	res, err := s.Client.GetItem(ctx, input)
	if err != nil {
		return models.UserProfile{}, fmt.Errorf("GetUserProfile: user_id=%s: %w", userID, err)
	}
	if res.Item == nil {
		return models.DefaultUserProfile(userID), nil
	}

	var profile models.UserProfile
	if err := attributevalue.UnmarshalMap(res.Item, &profile); err != nil {
		return models.UserProfile{}, fmt.Errorf("GetUserProfile: unmarshal failed user_id=%s: %w", userID, err)
	}
	return profile, nil
}

//overwrites the profile row for profile.UserID. PutItem
func (s *UserStore) UpdateUserPreferences(ctx context.Context, profile models.UserProfile) error {
	if profile.UserID == "" {
		return fmt.Errorf("UpdateUserPreferences: user_id is required")
	}

	item, err := attributevalue.MarshalMap(profile)
	if err != nil {
		return fmt.Errorf("UpdateUserPreferences: marshal failed user_id=%s: %w", profile.UserID, err)
	}

	_, err = s.Client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(s.TableName),
		Item:      item,
	})
	if err != nil {
		return fmt.Errorf("UpdateUserPreferences: PutItem failed user_id=%s: %w", profile.UserID, err)
	}
	return nil
}

//returns all active FCM tokens for the user that pass the severity filter
func (s *UserStore) GetFCMTokens(ctx context.Context, userID, severity string) ([]string, error) {
	profile, err := s.GetUserProfile(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("GetFCMTokens: user_id=%s: %w", userID, err)
	}

	if len(profile.FCMDeviceTokens) == 0 || !profile.ReceiveNotifications {
		return nil, nil
	}

	switch severity {
	case "CRITICAL":
		if !profile.ReceiveCritical {
			return nil, nil
		}
	case "WARNING":
		if !profile.ReceiveWarnings {
			return nil, nil
		}
	}

	tokens := make([]string, 0, len(profile.FCMDeviceTokens))
	for _, token := range profile.FCMDeviceTokens {
		if token != "" {
			tokens = append(tokens, token)
		}
	}
	return tokens, nil
}

// removes the profile row so DeleteAccount does not orphan FCM tokens
func (s *UserStore) Delete(ctx context.Context, userID string) error {
	_, err := s.Client.DeleteItem(ctx, &dynamodb.DeleteItemInput{
		TableName: aws.String(s.TableName),
		Key: map[string]types.AttributeValue{
			"user_id": &types.AttributeValueMemberS{Value: userID},
		},
	})
	if err != nil {
		return fmt.Errorf("Delete: user_id=%s: %w", userID, err)
	}
	return nil
}
