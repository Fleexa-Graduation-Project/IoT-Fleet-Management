package notifications

import (
	"context"
	"fmt"
	"log/slog"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

//handles pushing messages via FCM
type Service struct {
	fcmClient *messaging.Client
}

func NewService(credentialsFile string) (*Service, error) {
	opt := option.WithCredentialsFile(credentialsFile)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return nil, fmt.Errorf("error initializing firebase app: %w", err)
	}

	client, err := app.Messaging(context.Background())
	if err != nil {
		return nil, fmt.Errorf("error getting Messaging client: %w", err)
	}

	return &Service{
		fcmClient: client,
	}, nil
}

//sending a message to a severity-specific topic(filter by WARNING or CRITICAL)
func (s *Service) SendPushNotification(deviceID string, severity string, title string, body string) {
	if s == nil {
		slog.Warn("notification service unavailable, skipping sending it", "device_id", deviceID)
		return
	}

	// filter notifications based on user preference.
	topic := deviceID + "_" + severity

	message := &messaging.Message{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: map[string]string{
			"severity": severity,
		},
		Topic: topic,
	}

	response, err := s.fcmClient.Send(context.Background(), message)
	if err != nil {
		slog.Error("Failed to send push notification", "error", err, "device_id", deviceID)
		return
	}

	slog.Info("Successfully sent push notification", "response", response, "device_id", deviceID)
}