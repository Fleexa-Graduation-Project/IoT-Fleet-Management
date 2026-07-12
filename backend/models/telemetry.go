package models

type Telemetry struct {
	UserID    string                 `json:"user_id"    dynamodbav:"user_id"`
	DeviceID  string                 `json:"device_id"  dynamodbav:"device_id"`
	Timestamp EpochTime              `json:"timestamp"  dynamodbav:"timestamp"`
	Type      string                 `json:"type"       dynamodbav:"type"`
	Payload   map[string]interface{} `json:"payload"    dynamodbav:"payload"`
	ExpiresAt EpochTime              `json:"expires_at" dynamodbav:"ttl"`
}
