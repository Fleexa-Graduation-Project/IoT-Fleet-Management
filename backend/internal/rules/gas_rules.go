package rules

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/Fleexa-Graduation-Project/Backend/models"
)

func (engine *AlertEngine) HandleGas(ctx context.Context, userID, deviceID string, payload map[string]interface{}) {

	alarmOn, _ := payload["alarm_on"].(bool)
	status, _ := payload["status"].(string)

	if alarmOn || status == "WARNING" || status == "CRITICAL" {

		var gasLevel float64
		if val, ok := payload["gas_level"].(float64); ok {
			gasLevel = val
		} else if intVal, ok := payload["gas_level"].(int); ok {
			gasLevel = float64(intVal)
		}

		severity := "CRITICAL"
		if status == "WARNING" && !alarmOn {
			severity = "WARNING"
		}
		title := fmt.Sprintf("%s Gas Alert", TitleCaseSeverity(severity))
		description := fmt.Sprintf("Gas Level: %.0f PPM", gasLevel)

		err := engine.alertStore.SaveAlert(ctx, models.Alert{
			UserID:    userID,
			DeviceID:  deviceID,
			Type:      "gas-sensor",
			Severity:  severity,
			Timestamp: models.EpochTime(time.Now().Unix()),
			Payload: map[string]interface{}{
				"title":       title,
				"description": description,
				"gas_level":   gasLevel,
			},
		})

		if err != nil {
			slog.Error("failed to save gas alert to db", "error", err, "user_id", userID, "device_id", deviceID)
		} else {
			slog.Warn("gas alert triggered", "user_id", userID, "device_id", deviceID, "severity", severity)
			engine.Notify(ctx, userID, severity, title, description)
		}
	}
}
