package models

import "fmt"

type Alert struct {
	AlertID   string                 `json:"alert_id"   dynamodbav:"alert_id"`
	UserID    string                 `json:"user_id"    dynamodbav:"user_id"`
	DeviceID  string                 `json:"device_id"  dynamodbav:"device_id"`
	Timestamp EpochTime              `json:"timestamp"  dynamodbav:"timestamp"`
	Type      string                 `json:"type"       dynamodbav:"type"`
	Severity  string                 `json:"severity"   dynamodbav:"severity"`
	Payload   map[string]interface{} `json:"payload"    dynamodbav:"payload"`
	ExpiresAt EpochTime              `json:"expires_at" dynamodbav:"ttl"`
	IsRead    bool                   `json:"is_read"    dynamodbav:"is_read"`
}

// GenerateID builds a deterministic, unique alert_id.
func (a *Alert) GenerateID() {
	a.AlertID = fmt.Sprintf("%s#%s#%d", a.UserID, a.DeviceID, a.Timestamp.Int64())
}
