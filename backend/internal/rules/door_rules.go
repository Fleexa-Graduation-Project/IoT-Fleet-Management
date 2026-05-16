package rules

import (
	"context"
	"log/slog"
	"time"
	"sync"

	"github.com/Fleexa-Graduation-Project/Backend/models"
)

//1 min EventBridge Cron
func (engine *AlertEngine) CheckDoorTimeouts(ctx context.Context) {
	states, err := engine.stateStore.GetAllOpenDoors(ctx)
	if err != nil {
		slog.Error("failed to fetch states for door cron", "error", err)
		return
	}

	now := time.Now().Unix()
	var wg sync.WaitGroup

	for _, state := range states {
		if state.Type != "door-sensor" && state.Type != "door-actuator" {
			continue
		}

		var startTimestamp int64

		if lastUnlockFloat, ok := state.Payload["last_unlock"].(float64); ok {
			startTimestamp = int64(lastUnlockFloat)
		} else if lastChangeFloat, ok := state.Payload["last_change"].(float64); ok {
			startTimestamp = int64(lastChangeFloat)
		}

		if startTimestamp == 0 {
			continue
		}

		minutesOpen := float64(now-startTimestamp) / 60.0
		severity := ""
		description := ""

		//WARNING at 7 mins, CRITICAL at 15 mins, then a reminder if it's still open
		thresholds := []struct {
			minutes     float64
			severity    string
			description string
		}{
			{7, "WARNING", "Warning: The door has been left open."},
			{15, "CRITICAL", "Critical: Door open for 15 minutes. Please secure it."},
			{30, "CRITICAL", "Critical: Door still open after 30 minutes."},
			{60, "CRITICAL", "Critical: Door open for 1 hour. Immediate action required."},
			{120, "CRITICAL", "Critical: Door open for 2 hours. Possible security breach."},
		}

		for _, t := range thresholds {
			if minutesOpen >= t.minutes && minutesOpen < t.minutes+1.0 {
				severity = t.severity
				description = t.description
				break
			}
		}

		if severity != "" {
			wg.Add(1)
			go func(state models.DeviceState, sev, desc string) {
				defer wg.Done()
				engine.triggerDoorAlert(ctx, state, sev, desc)
			}(state, severity, description)
		}
	}
	wg.Wait()
}

func (engine *AlertEngine) triggerDoorAlert(ctx context.Context, state models.DeviceState, severity, description string) {
	err := engine.alertStore.SaveAlert(ctx, models.Alert{
		UserID:    state.UserID,
		DeviceID:  state.DeviceID,
		Type:      state.Type,
		Severity:  severity,
		Timestamp: time.Now().Unix(),
		Payload: map[string]interface{}{
			"description": description,
		},
	})

	if err != nil {
		slog.Error("failed to save door alert to db", "error", err, "user_id", state.UserID, "device_id", state.DeviceID)
		return
	}

	slog.Warn("door security event logged", "user_id", state.UserID, "device_id", state.DeviceID, "severity", severity)
	
	//send notification to app
	engine.Notify(ctx, state.UserID, severity, "Door Alert", description)
}