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
		log.Error("failed to initialize Cognito client", "error", err)
		panic(err)
	}
	if err := auth.InitJWKS(context.Background()); err != nil {
		log.Error("failed to initialize JWKS for token validation", "error", err)
		panic(err)
	}

	bucketName := os.Getenv("BUCKET_NAME")
	s3Fetcher, err := iot.NewS3Client(context.Background(), bucketName)
	if err != nil {
		log.Error("failed to initialize S3Client", "error", err)
		panic(err)
	}

	deviceHandler := &handlers.DeviceHandler{
		StateStore:     stateStore,
		TelemetryStore: telemetryStore,
		AlertStore:     alertStore,
		CommandStore:   commandStore,
		IoTPublisher:   iotPublisher,
		S3Fetcher:      s3Fetcher,
	}

	authHandler := &handlers.AuthHandler{Cognito: cognitoClient}

	router := gin.Default()

	router.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})

	//grouping routes
	v1 := router.Group("/api/v1")
	{
		v1.GET("/devices", deviceHandler.GetDevices)
		v1.GET("/alerts", deviceHandler.GetSortedAlerts)
		v1.GET("/devices/:id", deviceHandler.GetDeviceByID)
		v1.GET("/devices/:id/telemetry", deviceHandler.GetDeviceTelemetry)
		v1.GET("/devices/:id/alerts", deviceHandler.GetDeviceAlerts)
		v1.GET("/system/overview", deviceHandler.GetSystemOverview)
		v1.POST("/devices/:id/commands", deviceHandler.SendCommand)

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
				protected.GET("/profile", authHandler.GetProfile)
			}
		}
	}

	log.Info("api-service -> stores ready, starting lambda handler...")
	adapter := ginadapter.NewV2(router)
	lambda.Start(adapter.ProxyWithContext)
}
