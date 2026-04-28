package main

import (
"context"
"net/http"
"os"

"github.com/Fleexa-Graduation-Project/Backend/internal/api/handlers"
"github.com/Fleexa-Graduation-Project/Backend/internal/devices"
"github.com/Fleexa-Graduation-Project/Backend/internal/telemetry"
"github.com/Fleexa-Graduation-Project/Backend/pkg/db"
"github.com/Fleexa-Graduation-Project/Backend/pkg/logger"
"github.com/Fleexa-Graduation-Project/Backend/internal/alerts"
"github.com/Fleexa-Graduation-Project/Backend/internal/commands"
"github.com/Fleexa-Graduation-Project/Backend/internal/iot"

"github.com/aws/aws-lambda-go/events"
"github.com/aws/aws-lambda-go/lambda"
"github.com/aws/aws-sdk-go-v2/config"
ginadapter "github.com/awslabs/aws-lambda-go-api-proxy/gin"
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

//initializing the device holder
deviceHandler := &handlers.DeviceHandler{
StateStore:     stateStore,
TelemetryStore: telemetryStore,
AlertStore:     alertStore,
CommandStore:   commandStore,
IoTPublisher:   iotPublisher,
}

router := gin.Default()

router.GET("/ping", func(c *gin.Context) {
c.JSON(http.StatusOK, gin.H{"message": "pong"})
})

//grouping routes
v1 := router.Group("/api/v1")
{
v1.GET("/devices", deviceHandler.GetDevices)
v1.GET("/devices/:id", deviceHandler.GetDeviceByID)
v1.GET("/devices/:id/telemetry", deviceHandler.GetDeviceTelemetry)
v1.GET("/devices/:id/alerts", deviceHandler.GetDeviceAlerts)
v1.GET("/system/overview", deviceHandler.GetSystemOverview)
v1.POST("/devices/:id/commands", deviceHandler.SendCommand)
}

if os.Getenv("AWS_LAMBDA_FUNCTION_NAME") != "" {
log.Info("Running as AWS Lambda...")
ginLambda = ginadapter.New(router)
lambda.Start(Handler)
} else {
port := os.Getenv("PORT")
if port == "" {
port = "8080"
}
log.Info("Listening and serving HTTP on port: " + port)
if err := router.Run(":" + port); err != nil {
log.Error("Failed to start server", "error", err)
os.Exit(1)
}
}
}
