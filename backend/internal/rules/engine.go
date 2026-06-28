package rules

import (
	"context"
	"log/slog"

	"github.com/Fleexa-Graduation-Project/Backend/internal/alerts"
	"github.com/Fleexa-Graduation-Project/Backend/internal/devices"
	"github.com/Fleexa-Graduation-Project/Backend/internal/notifications"
	"github.com/Fleexa-Graduation-Project/Backend/internal/users"
)

type AlertEngine struct {
	alertStore *alerts.AlertStore
	stateStore *devices.StateStore
	notifier   *notifications.Service
	userStore  *users.UserStore
}

func NewAlertEngine(alertStore *alerts.AlertStore, stateStore *devices.StateStore, notifier *notifications.Service, userStore *users.UserStore) *AlertEngine {
	return &AlertEngine{
		alertStore: alertStore,
		stateStore: stateStore,
		notifier:   notifier,
		userStore:  userStore,
	}
}

func (e *AlertEngine) Notify(ctx context.Context, userID, severity, title, body string) {
	if e.userStore == nil {
		slog.Warn("user store unavailable, skipping notification", "user_id", userID, "severity", severity)
		return
	}

	tokens, err := e.userStore.GetFCMTokens(ctx, userID, severity)
	if err != nil {
		slog.Warn("failed to resolve FCM tokens, skipping notification", "user_id", userID, "severity", severity, "error", err)
		return
	}

	e.notifier.SendPushNotification(ctx, tokens, severity, title, body)
}
