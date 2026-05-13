package models

type UserProfile struct {
	UserID          string `json:"user_id" dynamodbav:"user_id"`
	FCMDeviceToken  string `json:"fcm_device_token" dynamodbav:"fcm_device_token"`
	ReceiveNotifications bool   `json:"receive_notifications" dynamodbav:"receive_notifications"`
	ReceiveCritical bool   `json:"receive_critical" dynamodbav:"receive_critical"`
	ReceiveWarnings bool   `json:"receive_warnings" dynamodbav:"receive_warnings"`
}

// First-time users must still receive critical + warning alerts
// until they explicitly opt out from the Settings screen.
func DefaultUserProfile(userID string) UserProfile {
	return UserProfile{
		UserID:               userID,
		FCMDeviceToken:       "",
		ReceiveNotifications: true,
		ReceiveCritical:      true,
		ReceiveWarnings:      true,
	}
}
