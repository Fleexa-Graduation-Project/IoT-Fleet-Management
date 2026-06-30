package main

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/Fleexa-Graduation-Project/Backend/internal/devices"
	"github.com/Fleexa-Graduation-Project/Backend/internal/iot"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/db"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/logger"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
)

var (
	log        *slog.Logger
	stateStore *devices.StateStore
	publisher  *iot.Publisher
)

func init() {
	log = logger.InitLogger()
	log.Info("ac-timer-watch lambda -> cold start...")

	if err := db.NewDynamoDBClient(context.Background()); err != nil {
		log.Error("failed to initialize dynamodb", "error", err)
		panic(err)
	}

	var err error
	stateStore, err = devices.NewStateStore()
	if err != nil {
		panic(fmt.Errorf("failed to init state store: %w", err))
	}

	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		panic(fmt.Errorf("failed to load aws config: %w", err))
	}
	publisher = iot.NewPublisher(cfg)

	log.Info("ac-timer-watch lambda -> cold start complete, stores ready")
}

func handler(ctx context.Context, _ map[string]interface{}) error {
	now := time.Now().Unix()
	log.Info("ac-timer-watch -> scanning for expired AC timers...")

	expired, err := stateStore.GetExpiredACTimers(ctx, now)
	if err != nil {
		log.Error("failed to scan expired AC timers", "error", err)
		return err
	}

	if len(expired) == 0 {
		log.Info("ac-timer-watch -> no expired timers")
		return nil
	}

	for _, state := range expired {
		topic := fmt.Sprintf("devices/%s/%s/commands", state.UserID, state.DeviceID)
		mqttPayload := map[string]interface{}{
			"request_id": fmt.Sprintf("timer-off-%d", now),
			"action":     "set_power",
			"parameters": map[string]interface{}{"power_state": "OFF"},
		}

		if err := publisher.Publish(ctx, topic, mqttPayload); err != nil {
			log.Error("failed to publish timer OFF command",
				"device_id", state.DeviceID,
				"user_id", state.UserID,
				"error", err)
			continue
		}

		clearFields := map[string]interface{}{
			"power_state":         "OFF",
			"timer_end_timestamp": int64(0),
			"last_turned_on":      int64(0),
		}
		if updateErr := stateStore.UpdateACFields(ctx, state.UserID, state.DeviceID, clearFields, "OFF"); updateErr != nil {
			log.Warn("failed to clear AC timer state after shutoff",
				"device_id", state.DeviceID,
				"error", updateErr)
		}

		log.Info("ac-timer-watch -> timer expired, AC turned off",
			"device_id", state.DeviceID,
			"user_id", state.UserID)
	}

	return nil
}

func main() {
	lambda.Start(handler)
}
