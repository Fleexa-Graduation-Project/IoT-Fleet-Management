package rules

import (
	"context"
	"log/slog"
	"strings"
	"sync"
	"time"

	"github.com/Fleexa-Graduation-Project/Backend/models"
)

//1 min EventBridge Cron
func (engine *AlertEngine) CheckDoorTimeouts(ctx context.Context) {
	states, err := engine.stateStore.GetAllStates(ctx)
	if err != nil {
		slog.Error("failed to fetch states for door cron", "error", err)
		return
	}

	now := time.Now().Unix()
	var wg sync.WaitGroup

	for _, state := range states {
		if state.Type == "door-sensor" || state.Type == "door-actuator" {

			isOpen := false
			if openBool, ok := state.Payload["open"].(bool); 
			ok {
				isOpen = openBool
			} else if openStr, ok := state.Payload["open"].(string); 
			ok {
				lower := strings.ToLower(openStr)
				isOpen = (lower == "true" || lower == "open")
			}

			if isOpen {
				var startTimestamp int64

				if lastUnlockFloat, ok := state.Payload["last_unlock"].(float64); ok {
					startTimestamp = int64(lastUnlockFloat)
				} else if lastChangeFloat, ok := state.Payload["last_change"].(float64); ok {
					startTimestamp = int64(lastChangeFloat)
				}

				if startTimestamp == 0 {
					continue
				}

				minutesUnlocked := float64(now-startTimestamp) / 60.0
				severity := ""
				description := ""

				// 7 mins WARNING notification
				if minutesUnlocked >= 7.0 && minutesUnlocked < 8.0 {
					severity = "WARNING"
					description = "Warning: The door was left open."
				}

				// 15 mins CRITICAL notification
				if minutesUnlocked >= 15.0 && minutesUnlocked < 16.0 {
					severity = "CRITICAL"
					description = "Critical: The door has been open for 15 minutes. Please secure it."
				}

				if severity != "" {
					wg.Add(1)

					go func(deviceID, deviceType, sev, desc string) {
						defer wg.Done()
						engine.triggerDoorAlert(ctx, deviceID, deviceType, sev, desc)
					}(state.DeviceID, state.Type, severity, description)
				}
			}
		}
	}
	wg.Wait()
}

func (engine *AlertEngine) triggerDoorAlert(ctx context.Context, deviceID string, deviceType string, severity string, description string) {

	err := engine.alertStore.SaveAlert(ctx, models.Alert{
		DeviceID:  deviceID,
		Type:      deviceType, 
		Severity:  severity,
		Timestamp: time.Now().Unix(),
		Payload: map[string]interface{}{
			"description": description,
		},
	})

	if err == nil {
		slog.Warn("Door Security Event Logged", "device_id", deviceID, "severity", severity)
		
		// send notification to app
		engine.notifier.SendPushNotification(deviceID, severity, description)
	} else {
		slog.Error("failed to save door alert to db", "error", err)
	}
}