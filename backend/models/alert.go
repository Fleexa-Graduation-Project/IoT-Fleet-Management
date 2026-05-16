package models

import "fmt"

type Alert struct {
	AlertID   string                 `json:"alert_id"  dynamodbav:"alert_id"`
	UserID    string                 `json:"user_id"    dynamodbav:"user_id"`
	DeviceID  string                 `json:"device_id" dynamodbav:"device_id"`
	Timestamp int64                  `json:"timestamp" dynamodbav:"timestamp"`
	Type      string                 `json:"type"      dynamodbav:"type"`
	Severity  string                 `json:"severity"  dynamodbav:"severity"`
	Payload   map[string]interface{} `json:"payload"   dynamodbav:"payload"`
	ExpiresAt int64                  `json:"expires_at" dynamodbav:"expires_at"`
}

//helper to generate a deterministic, unique alert_id
func (a *Alert) GenerateID() {
	a.AlertID = fmt.Sprintf("%s#%s#%d", a.UserID, a.DeviceID, a.Timestamp)
}