package models

type Command struct {
	RequestID  string                 `json:"request_id" dynamodbav:"command_id"`
	UserID     string                 `json:"user_id"    dynamodbav:"user_id"`
	DeviceID   string                 `json:"device_id"  dynamodbav:"device_id"`
	Timestamp  EpochTime              `json:"timestamp"  dynamodbav:"timestamp"`
	Action     string                 `json:"action"     dynamodbav:"action"`
	Parameters map[string]interface{} `json:"parameters" dynamodbav:"parameters"`
	ExpiresAt  EpochTime              `json:"expires_at" dynamodbav:"expires_at"`
}
