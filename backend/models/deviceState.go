package models

type DeviceState struct {
	UserID               string                 `json:"user_id"                          dynamodbav:"user_id"`
	DeviceID             string                 `json:"device_id"                        dynamodbav:"device_id"`
	Type                 string                 `json:"type"                             dynamodbav:"type"`
	Status               string                 `json:"status"                           dynamodbav:"status"`
	OperationalState     string                 `json:"operational_state"                dynamodbav:"operational_state"`
	Health               string                 `json:"health"                           dynamodbav:"health"`
	Payload              map[string]interface{} `json:"payload"                          dynamodbav:"payload"`
	NormalUnlockDuration float64                `json:"normal_unlock_duration,omitempty" dynamodbav:"normal_unlock_duration"`
	LastSeenAt           EpochTime              `json:"last_seen_at"                     dynamodbav:"last_seen_at"`
	LastUpdated          EpochTime              `json:"-"                                dynamodbav:"updated_at"`
}
