package rules

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/Fleexa-Graduation-Project/Backend/models"
)

//pushes an informational notification when an ac timer finshies
func (engine *AlertEngine) NotifyACTimerExpired(ctx context.Context, state models.DeviceState) {
	description := fmt.Sprintf("%s has been turned off automatically — the timer finished.", state.DeviceID)

	lastOn, lastOnOk := state.Payload["last_turned_on"].(float64)
	endTs, endTsOk := state.Payload["timer_end_timestamp"].(float64)
	if lastOnOk && endTsOk && endTs > lastOn {
		minutes := (int64(endTs) - int64(lastOn)) / 60
		description = fmt.Sprintf("%s turned off after running for %d minutes, as scheduled.", state.DeviceID, minutes)
	}

	err := engine.alertStore.SaveAlert(ctx, models.Alert{
		UserID:    state.UserID,
		DeviceID:  state.DeviceID,
		Type:      state.Type,
		Severity:  "INFO",
		Timestamp: models.EpochTime(time.Now().Unix()),
		Payload: map[string]interface{}{
			"description": description,
		},
	})

	if err != nil {
		slog.Error("failed to save ac timer alert to db", "error", err, "user_id", state.UserID, "device_id", state.DeviceID)
		return
	}

	slog.Info("ac timer expired, ac turned off", "user_id", state.UserID, "device_id", state.DeviceID)

	engine.Notify(ctx, state.UserID, "INFO", "AC Timer Finished", description)
}
