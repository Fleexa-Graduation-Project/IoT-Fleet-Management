package rules

import (
	"context"
	"log/slog"
	"time"

	"github.com/Fleexa-Graduation-Project/Backend/models"
)

func (engine *AlertEngine) CheckDoorTimeouts(ctx context.Context) {
	states, err := engine.stateStore.GetAllStates(ctx)
	if err != nil {
		slog.Error("failed to fetch states for door cron", "error", err)
		return
	}

	now := time.Now().Unix()

	for _, state := range states {
		if state.Type == "door-actuator" {
			lockState, _ := state.Payload["lock_state"].(string)
			
			if lockState == "UNLOCKED" {
				// get the timestamp of when it was unlocked
				lastUnlockFloat, ok := state.Payload["last_unlock"].(float64)
				if !ok {
					continue
				}
				
				lastUnlock := int64(lastUnlockFloat)
				minutesUnlocked := float64(now - lastUnlock) / 60.0

				if minutesUnlocked >= 15.0 && minutesUnlocked < 16.0 {
					engine.triggerDoorCritical(state.DeviceID)
				} else if minutesUnlocked >= 7.0 && minutesUnlocked < 8.0 {
					engine.triggerDoorWarning(state.DeviceID)
				} else if minutesUnlocked >= 45.0 && int(minutesUnlocked)%30 == 0 {
					// reminder loop: hits at 45m, 75m, 105m, etc.
					engine.triggerDoorReminder(state.DeviceID)
				}
			}
		}
	}
}

func (engine *AlertEngine) triggerDoorWarning(deviceID string) {
	//save WARNING to database
	err := engine.alertStore.SaveAlert(context.Background(), models.Alert{
		DeviceID:  deviceID,
		Type:      "door-actuator",
		Severity:  "WARNING",
		Timestamp: time.Now().Unix(),
		Payload: map[string]interface{}{
			"description": "Door left open for > 7 mins",
		},
	})

	if err == nil {
		slog.Warn("WARNING: Door open for 7 minutes", "device_id", deviceID)
		engine.notifier.SendPushNotification(deviceID, "Warning", "Door left open > 7 mins")
	} else {
		slog.Error("failed to save door warning to db", "error", err)
	}
}

func (engine *AlertEngine) triggerDoorCritical(deviceID string) {
	//save CRITICAL to db
	err := engine.alertStore.SaveAlert(context.Background(), models.Alert{
		DeviceID:  deviceID,
		Type:      "door-actuator",
		Severity:  "CRITICAL",
		Timestamp: time.Now().Unix(),
		Payload: map[string]interface{}{
			"description": "Door left open for > 15 mins",
		},
	})

	if err == nil {
		slog.Error("CRITICAL: Door open for 15 minutes!", "device_id", deviceID)
		engine.notifier.SendPushNotification(deviceID, "CRITICAL", "Door left open > 15 mins!")
	} else {
		slog.Error("failed to save door critical alert to db", "error", err)
	}
}

func (engine *AlertEngine) triggerDoorReminder(deviceID string) {
	slog.Warn("REMINDER: Door is STILL open!", "device_id", deviceID)
	engine.notifier.SendPushNotification(deviceID, "REMINDER", "Your door is still open!")
}