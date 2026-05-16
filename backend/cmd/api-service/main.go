package main

import (
	"context"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	ginadapter "github.com/awslabs/aws-lambda-go-api-proxy/gin"

	"github.com/Fleexa-Graduation-Project/Backend/internal/alerts"
	"github.com/Fleexa-Graduation-Project/Backend/internal/api/handlers"
	"github.com/Fleexa-Graduation-Project/Backend/internal/auth"
	"github.com/Fleexa-Graduation-Project/Backend/internal/commands"
	"github.com/Fleexa-Graduation-Project/Backend/internal/devices"
	"github.com/Fleexa-Graduation-Project/Backend/internal/iot"
	"github.com/Fleexa-Graduation-Project/Backend/internal/telemetry"
	"github.com/Fleexa-Graduation-Project/Backend/internal/users"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/db"
	"github.com/Fleexa-Graduation-Project/Backend/pkg/logger"

	"github.com/aws/aws-sdk-go-v2/config"

	"github.com/gin-gonic/gin"
)

var ginLambda *ginadapter.GinLambda

func Handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// If no name is provided in the HTTP request body, throw an error
	return ginLambda.ProxyWithContext(ctx, req)
}

func main() {
	log := logger.InitLogger()
	log.Info("starting fleexa api server...")

	if err := db.NewDynamoDBClient(context.Background()); err != nil {
		log.Error("failed to initialize dynamodb", "error", err)
		panic(err)
	}

	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Error("failed to load aws config for iot", "error", err)
		panic(err)
	}

	stateStore, err := devices.NewStateStore()
	if err != nil {
		log.Error("failed to initialize StateStore", "error", err)
		panic(err)
	}

	telemetryStore, err := telemetry.NewTelemetryStore()
	if err != nil {
		log.Error("failed to initialize TelemetryStore", "error", err)
		panic(err)
	}

	alertStore, err := alerts.NewAlertStore()
	if err != nil {
		log.Error("Failed to initialize AlertStore", "error", err)
		panic(err)
	}
	commandStore, err := commands.NewCommandStore()
	if err != nil {
		log.Error("Failed to initialize CommandStore", "error", err)
		panic(err)
	}
	iotPublisher := iot.NewPublisher(cfg)

	cognitoClient, err := auth.NewCognitoClient(cfg)
	if err != nil {
		log.Warn("Cognito client failed — auth endpoints will be unavailable", "error", err)
		cognitoClient = nil // pass nil, guard in authHandler methods
	}

	if err := auth.InitJWKS(context.Background()); err != nil {
		log.Warn("JWKS initialization failed — auth endpoints will be unavailable", "error", err)
	}
	userStore, err := users.NewUserStore()
	if err != nil {
		log.Error("failed to initialize UserStore", "error", err)
		panic(err)
	}


	bucketName := os.Getenv("BUCKET_NAME")
	var s3Fetcher *iot.S3Client
	if bucketName != "" {
		s3Fetcher, err = iot.NewS3Client(context.Background(), bucketName)
		if err != nil {
			log.Warn("S3Client initialization failed — certificate fetching unavailable", "error", err)
			// Don't panic — app still starts
		}
	} else {
		log.Warn("BUCKET_NAME not set — S3Client skipped")
	}

	deviceHandler := &handlers.DeviceHandler{
		StateStore:     stateStore,
		TelemetryStore: telemetryStore,
		AlertStore:     alertStore,
		CommandStore:   commandStore,
		IoTPublisher:   iotPublisher,
		S3Fetcher:      s3Fetcher,
	}

	authHandler := &handlers.AuthHandler{Cognito: cognitoClient, UserStore: userStore}
	userHandler := &handlers.UserHandler{UserStore: userStore}
	router := gin.Default()

	router.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})

	//grouping routes
	v1 := router.Group("/api/v1")
	device := v1.Group("", auth.Middleware())
	{
		device.GET("/devices", deviceHandler.GetDevices)
		device.GET("/alerts", deviceHandler.GetSortedAlerts)
		device.GET("/devices/:id", deviceHandler.GetDeviceByID)
		device.GET("/devices/:id/telemetry", deviceHandler.GetDeviceTelemetry)
		device.GET("/devices/:id/alerts", deviceHandler.GetDeviceAlerts)
		device.GET("/system/overview", deviceHandler.GetSystemOverview)
		device.POST("/devices/:id/commands", deviceHandler.SendCommand)

		authRoutes := v1.Group("/auth")
		{
			authRoutes.POST("/signup", authHandler.SignUp)
			authRoutes.POST("/signin", authHandler.SignIn)
			authRoutes.POST("/refresh", authHandler.RefreshTokens)
			authRoutes.POST("/forgot-password", authHandler.ForgotPassword)
			authRoutes.POST("/reset-password", authHandler.ResetPassword)

			protected := authRoutes.Group("", auth.Middleware())
			{
				protected.POST("/change-password", authHandler.ChangePassword)
				protected.DELETE("/account", authHandler.DeleteAccount)
				protected.GET("/profile", authHandler.GetProfile)
			}
		}
		userRoutes := v1.Group("/users", auth.Middleware())
		{
			userRoutes.GET("/preferences", userHandler.GetPreferences)
			userRoutes.PUT("/preferences", userHandler.UpdatePreferences)
		}

	}

	log.Info("api-service -> stores ready, starting lambda handler...")
	adapter := ginadapter.NewV2(router)
	lambda.Start(adapter.ProxyWithContext)
}
