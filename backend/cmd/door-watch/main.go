package main

import (
	"context"
	"fmt"
	"os"
	"log/slog"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/Fleexa-Graduation-Project/Backend/internal/alerts"
	"github.com/Fleexa-Graduation-Project/Backend/internal/devices"
	"github.com/Fleexa-Graduation-Project/Backend/internal/notifications"
	"github.com/Fleexa-Graduation-Project/Backend/internal/rules"
	"github.com/Fleexa-Graduation-Project/Backend/internal/users"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/db"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/logger"
)

var (
	log         *slog.Logger
	alertEngine *rules.AlertEngine
)

func init() {
	log = logger.InitLogger()
	log.Info("door-watch lambda -> cold start...")

	if err := db.NewDynamoDBClient(context.Background()); err != nil {
		log.Error("failed to initialize dynamodb", "error", err)
		panic(err)
	}

	alertStore, err := alerts.NewAlertStore()
	if err != nil {
		panic(fmt.Errorf("failed to init alert store: %w", err))
	}

	stateStore, err := devices.NewStateStore()
	if err != nil {
		panic(fmt.Errorf("failed to init device state store: %w", err))
	}

	firebaseKeyPath := os.Getenv("FIREBASE_CREDENTIALS")
	if firebaseKeyPath == "" {
		firebaseKeyPath = "./firebase-adminsdk.json"
	}

	notifier, err := notifications.NewService(firebaseKeyPath)
	if err != nil {
		log.Error("failed to init notification service (firebase)", "error", err)
	}

	userStore, userErr := users.NewUserStore()
	if userErr != nil {
		log.Warn("user store unavailable, push notifications will be skipped", "error", userErr)
		userStore = nil
	}

	alertEngine = rules.NewAlertEngine(alertStore, stateStore, notifier, userStore)

	log.Info("door-watch lambda -> cold start complete, stores ready")
}

func handler(ctx context.Context, _ map[string]interface{}) error {
	log.Info("door-watch -> scanning all door devices for timeout violations...")
	alertEngine.CheckDoorTimeouts(ctx)
	log.Info("door-watch -> scan complete")
	return nil
}

func main() {
	lambda.Start(handler)
}
