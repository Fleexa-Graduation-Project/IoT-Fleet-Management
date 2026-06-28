package ingestion

import (
	"context"
	"errors"
	"time"
	"fmt"
	"log/slog"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"

	"github.com/Fleexa-Graduation-Project/Backend/internal/alerts"
	"github.com/Fleexa-Graduation-Project/Backend/internal/devices"
	"github.com/Fleexa-Graduation-Project/Backend/internal/rules"
	"github.com/Fleexa-Graduation-Project/Backend/internal/telemetry"
	"github.com/Fleexa-Graduation-Project/Backend/internal/validation"
	"github.com/Fleexa-Graduation-Project/Backend/models"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/db"
)

type Service struct {
	Logger         *slog.Logger
	TelemetryStore *telemetry.TelemetryStore
	AlertStore     *alerts.AlertStore
	StateStore     *devices.StateStore
	Engine         *rules.AlertEngine
}

func (s *Service) HandleRequest(ctx context.Context, event map[string]interface{}) (err error) {
	start := time.Now()
	defer func() {
		if r := recover(); r != nil {
			s.Logger.Error("CRITICAL: lambda panic recovered", "panic", r)
			err = fmt.Errorf("internal server error!!")
		}

		duration := time.Since(start)
		s.Logger.Info("lambda execution complete",
			"execution_time_ms", duration.Milliseconds(),
			"execution_time", duration.String(),
			"success", err == nil,
		)
	}()

	deviceID, messageType, envelope, isBatch, err := validation.ValidateMessage(event)
	if err != nil {
		s.logValidationError(err, envelope.DeviceID)
		return err
	}

	switch messageType {
	case "telemetry":
		return s.handleTelemetry(ctx, deviceID, envelope, isBatch)

	case "alerts":
		return s.handleAlert(ctx, deviceID, envelope)

	default:
		return fmt.Errorf("unknown message type: %s", messageType)
	}
}

func (service *Service) handleTelemetry(ctx context.Context, deviceID string, envelope models.MQTTEnvelope, isBatch bool) error {

	if isBatch {
		items, ok := envelope.Payload["items"].([]interface{})
		if !ok {
			return fmt.Errorf("invalid batch format: items is not a list")
		}

		service.Logger.Info("processing batch telemetry", "user_id", envelope.UserID, "device_id", deviceID, "count", len(items))

		var telemetryList []models.Telemetry
		var latestReading models.Telemetry

		for _, itemRaw := range items {
			itemMap, ok := itemRaw.(map[string]interface{})
			if !ok {
				service.Logger.Warn("skipping invalid item in batch", "device_id", deviceID)
				continue
			}

			if err := validation.ValidatePayload(envelope.Type, itemMap); err != nil {
				service.Logger.Warn("skipping malformed payload in batch", "error", err)
				continue
			}

			// Start with the envelope-level timestamp; override per-item if present.
			timestamp := models.EpochTime(envelope.Timestamp)
			if itemTs, ok := itemMap["ts"].(float64); ok {
				timestamp = models.EpochTime(int64(itemTs))
			}

			t := models.Telemetry{
				UserID:    envelope.UserID,
				DeviceID:  deviceID,
				Timestamp: timestamp,
				Type:      envelope.Type,
				Payload:   itemMap,
			}

			telemetryList = append(telemetryList, t)

			if latestReading.Timestamp == 0 || t.Timestamp > latestReading.Timestamp {
				latestReading = t
			}
		}

		if len(telemetryList) > 0 {
			if err := service.TelemetryStore.SaveTelemetryBatch(ctx, telemetryList); err != nil {
				service.Logger.Error("failed to save batch telemetry", "error", err)
				return err
			}

			// Broadcast status update to all users
			userIDs := service.fetchAllUsers(ctx)
			if len(userIDs) == 0 {
				return service.StateStore.UpdateFromTelemetry(ctx, latestReading)
			}
			
			var lastErr error
			originalUserID := latestReading.UserID
			for _, uid := range userIDs {
				latestReading.UserID = uid
				if err := service.StateStore.UpdateFromTelemetry(ctx, latestReading); err != nil {
					lastErr = err
				}
			}
			latestReading.UserID = originalUserID // restore
			return lastErr
		}
		return nil
	}

	data := models.Telemetry{
		UserID:    envelope.UserID,
		DeviceID:  envelope.DeviceID,
		Timestamp: models.EpochTime(envelope.Timestamp),
		Type:      envelope.Type,
		Payload:   envelope.Payload,
	}

	service.Logger.Info("saving single telemetry", "user_id", envelope.UserID, "device_id", deviceID)

	if envelope.Type == "gas-sensor" {
		service.Engine.HandleGas(ctx, envelope.UserID, envelope.DeviceID, envelope.Payload)
	}

	if envelope.Type == "gas-sensor" {
		service.Engine.HandleGas(ctx, envelope.DeviceID, envelope.Payload)
	}

	if err := service.TelemetryStore.SaveTelemetry(ctx, data); err != nil {
		service.Logger.Error("failed to save telemetry", "error", err)
		return err
	}

	// Broadcast status update to all users
	userIDs := service.fetchAllUsers(ctx)
	if len(userIDs) == 0 {
		return service.StateStore.UpdateFromTelemetry(ctx, data)
	}

	var lastErr error
	originalUserID := data.UserID
	for _, uid := range userIDs {
		data.UserID = uid
		if err := service.StateStore.UpdateFromTelemetry(ctx, data); err != nil {
			lastErr = err
		}
	}
	data.UserID = originalUserID // restore

	return lastErr
}

func (service *Service) handleAlert(ctx context.Context, deviceID string, envelope models.MQTTEnvelope) error {
	severity, _ := envelope.Payload["severity"].(string)

	alert := models.Alert{
		UserID:    envelope.UserID,
		DeviceID:  envelope.DeviceID,
		Timestamp: models.EpochTime(envelope.Timestamp),
		Type:      envelope.Type,
		Severity:  severity,
		Payload:   envelope.Payload,
	}

	alert.GenerateID()

	if err := service.AlertStore.SaveAlert(ctx, alert); err != nil {
		return err
	}

	service.Logger.Info("alert saved, sending notification to", "user_id", envelope.UserID, "device_id", deviceID, "severity", severity)

	title := fmt.Sprintf("%s — %s", severity, envelope.Type)
	description, _ := envelope.Payload["description"].(string)
	if description == "" {
		description = fmt.Sprintf("%s alert triggered", envelope.Type)
	}
	service.Engine.Notify(ctx, envelope.UserID, severity, title, description)

	return service.StateStore.UpdateHeartbeat(ctx, envelope.UserID, deviceID)
}

func (service *Service) logValidationError(err error, deviceID string) {
	switch {
	case errors.Is(err, validation.ErrInvalidEvent), errors.Is(err, validation.ErrInvalidEnvelope):
		service.Logger.Warn("invalid message envelope", "error", err)
	case errors.Is(err, validation.ErrInvalidPayload):
		service.Logger.Warn("invalid payload", "device_id", deviceID, "error", err)
	case errors.Is(err, validation.ErrInvalidTopic):
		service.Logger.Warn("invalid topic", "error", err)
	default:
		service.Logger.Error("unexpected validation error", "error", err)
	}
}

func (service *Service) fetchAllUsers(ctx context.Context) []string {
	var userIDs []string
	tableName := os.Getenv("USERS_TABLE")
	if tableName == "" {
		service.Logger.Warn("USERS_TABLE environment variable not set, cannot broadcast status")
		return userIDs
	}

	input := &dynamodb.ScanInput{
		TableName:            aws.String(tableName),
		ProjectionExpression: aws.String("user_id"),
	}

	paginator := dynamodb.NewScanPaginator(db.Client, input)
	for paginator.HasMorePages() {
		page, err := paginator.NextPage(ctx)
		if err != nil {
			service.Logger.Error("failed to scan users table", "error", err)
			break
		}
		for _, item := range page.Items {
			if uid, ok := item["user_id"]; ok {
				if s, ok := uid.(*types.AttributeValueMemberS); ok {
					userIDs = append(userIDs, s.Value)
				}
			}
		}
	}
	return userIDs
}
