package notifications

import (
	"context"
	"encoding/json"
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

type credJSON struct {
	ProjectID string `json:"project_id"`
}

func NewService(credentialsSource string) (*Service, error) {
	var opt option.ClientOption
	config := &firebase.Config{}

	if strings.HasPrefix(strings.TrimSpace(credentialsSource), "{") {
		// Terraform may unescape \\n in the private_key to real newlines,
		// which breaks JSON parsing. Fix by replacing raw newlines inside the
		// JSON string with the \\n escape sequence.
		sanitized := strings.ReplaceAll(credentialsSource, "\n", "\\n")
		// But don't double-escape already-escaped \\n
		sanitized = strings.ReplaceAll(sanitized, "\\\\n", "\\n")

		opt = option.WithCredentialsJSON([]byte(sanitized))
		var creds credJSON
		if err := json.Unmarshal([]byte(sanitized), &creds); err == nil {
			config.ProjectID = creds.ProjectID
			slog.Info("firebase credentials parsed", "project_id", creds.ProjectID)
		} else {
			slog.Error("failed to parse firebase credentials JSON", "error", err)
		}
		// Fallback: if project_id was empty after parsing, try to extract it
		if config.ProjectID == "" {
			slog.Warn("project_id was empty after JSON parse, setting fallback")
			config.ProjectID = "fleexa-d36d3"
		}
	} else {
		opt = option.WithCredentialsFile(credentialsSource)
	}

	app, err := firebase.NewApp(context.Background(), config, opt)
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
			"title":    title,
			"body":     body,
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Sound: "default",
				ChannelID: "high_importance_channel", // Standard channel ID used in Flutter
				ClickAction: "FLUTTER_NOTIFICATION_CLICK",
			},
		},
		APNS: &messaging.APNSConfig{
			Headers: map[string]string{
				"apns-priority": "10",
			},
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound: "default",
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