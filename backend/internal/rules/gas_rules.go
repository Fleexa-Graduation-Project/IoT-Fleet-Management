package rules

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/Fleexa-Graduation-Project/Backend/models"
)

func (engine *AlertEngine) HandleGas(ctx context.Context, deviceID string, payload map[string]interface{}) {
	
	alarmOn, _ := payload["alarm_on"].(bool)
	status, _ := payload["status"].(string)

	if alarmOn || status == "WARNING" || status == "CRITICAL" {
		
		ppmLevel := "Unknown"
		if val, ok := payload["gas_level"].(float64); ok {
			ppmLevel = fmt.Sprintf("%.0f PPM", val)
		} else if intVal, ok := payload["gas_level"].(int); ok {
			ppmLevel = fmt.Sprintf("%d PPM", intVal)
		}

		severity := "CRITICAL"
		description := "Gas level critical"
		if status == "WARNING" && !alarmOn {
			severity = "WARNING"
			description = "Gas spike detected"
		}

		// save the alert to db with context
		err := engine.alertStore.SaveAlert(ctx, models.Alert{
			DeviceID:  deviceID,
			Type:      "gas-sensor",
			Severity:  severity,
			Timestamp: time.Now().Unix(),
			Payload: map[string]interface{}{
				"description": description,
				"gas_level":   ppmLevel,
			},
		})

		if err != nil {
			slog.Error("failed to save gas alert to db", "error", err)
		} else {
			slog.Error("gas alert triggered!", "device_id", deviceID, "severity", severity)
			// send push notification
			engine.notifier.SendPushNotification(deviceID, "Gas Alert", description)
		}
	}
}