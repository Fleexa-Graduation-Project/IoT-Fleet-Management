package notifications

import (
	"context"
	"fmt"
	"log/slog"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

//handles pushing messages via FCM
type Service struct {
	fcmClient *messaging.Client
}


func NewService(credentialsSource string) (*Service, error) {
	var opt option.ClientOption
	if strings.HasPrefix(strings.TrimSpace(credentialsSource), "{") {
		opt = option.WithCredentialsJSON([]byte(credentialsSource))
	} else {
		opt = option.WithCredentialsFile(credentialsSource)
	}
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

//sending a message to a severity-specific topic(filter by WARNING or CRITICAL) to all of the user's registered devices
func (s *Service) SendPushNotification(ctx context.Context, tokens []string, severity, title, body string) {
	if s == nil {
		slog.Warn("notification service unavailable, skipping sending it")
		return
	}
	if len(tokens) == 0 {
		slog.Info("no FCM tokens for user, skipping notification", "severity", severity)
		return
	}

	message := &messaging.MulticastMessage{
		Tokens: tokens,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: map[string]string{
			"severity": severity,
		},
		Android: &messaging.AndroidConfig{
			Notification: &messaging.AndroidNotification{
				Sound: "alert_sound",
			},
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound: "alert_sound.wav",
				},
			},
		},
	}

	response, err := s.fcmClient.SendEachForMulticast(ctx, message)
	if err != nil {
		slog.Error("failed to send push notifications", "error", err, "severity", severity)
		return
	}

	slog.Info("push notifications sent",
		"success_count", response.SuccessCount,
		"failure_count", response.FailureCount,
		"severity", severity,
	)

	for i, r := range response.Responses {
		if !r.Success {
			slog.Error("fcm token delivery failed",
				"token_index", i,
				"token", tokens[i],
				"error", r.Error,
			)
		}
	}
}