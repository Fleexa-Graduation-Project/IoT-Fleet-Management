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

//sending a message to a specific device topic
func (s *Service) SendPushNotification(deviceID string, title string, body string) {
	// For now, we will send to an FCM topic based on the device ID.
	// The Flutter app will subscribe to this topic (e.g., "door-actuator-01") to receive alerts.
	topic := deviceID

	message := &messaging.Message{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
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