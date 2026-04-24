package rules

import (
	"github.com/Fleexa-Graduation-Project/Backend/internal/alerts"
	"github.com/Fleexa-Graduation-Project/Backend/internal/devices"
	"github.com/Fleexa-Graduation-Project/Backend/internal/notifications"
)

type AlertEngine struct {
	alertStore *alerts.AlertStore
	stateStore *devices.StateStore 
	notifier   *notifications.Service 
}

func NewAlertEngine(alertStore *alerts.AlertStore, stateStore *devices.StateStore, notifier *notifications.Service) *AlertEngine {
	return &AlertEngine{
		alertStore: alertStore,
		stateStore: stateStore,
		notifier:   notifier,
	}
}

