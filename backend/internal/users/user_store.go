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

// GetUserProfile returns the stored profile for userID, or a safe default
// (both toggles = true) if no row exists yet.
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

// UpdateUserPreferences overwrites the profile row for profile.UserID. PutItem
// is intentional: the row is tiny and the handler always sends the full
// profile, so this costs 1 WCU vs. 1 RCU + 1 WCU for UpdateItem.
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

// Delete removes the profile row so DeleteAccount does not orphan FCM tokens
// or preference data after Cognito deletes the user.
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
