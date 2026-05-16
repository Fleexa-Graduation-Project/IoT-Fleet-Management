package models

type UserProfile struct {
	UserID          string `json:"user_id" dynamodbav:"user_id"`
    FCMDeviceTokens map[string]string `json:"fcm_device_tokens" dynamodbav:"fcm_device_tokens"`	
	ReceiveNotifications bool   `json:"receive_notifications" dynamodbav:"receive_notifications"`
	ReceiveCritical bool   `json:"receive_critical" dynamodbav:"receive_critical"`
	ReceiveWarnings bool   `json:"receive_warnings" dynamodbav:"receive_warnings"`
}

//as default, users receive critical + warning alerts
func DefaultUserProfile(userID string) UserProfile {
	return UserProfile{
		UserID:               userID,
		FCMDeviceTokens:      map[string]string{},
		ReceiveNotifications: true,
		ReceiveCritical:      true,
		ReceiveWarnings:      true,
	}
}
