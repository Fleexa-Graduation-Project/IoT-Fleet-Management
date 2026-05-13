package handlers

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/Fleexa-Graduation-Project/Backend/internal/users"
	"github.com/Fleexa-Graduation-Project/Backend/models"
)

type UserHandler struct {
	UserStore *users.UserStore
}

// GET /api/v1/users/preferences
func (h *UserHandler) GetPreferences(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	profile, err := h.UserStore.GetUserProfile(c.Request.Context(), userID)
	if err != nil {
		slog.Error("GetPreferences: store read failed", "user_id", userID, "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load preferences"})
		return
	}
	c.JSON(http.StatusOK, profile)
}

// PUT /api/v1/users/preferences
func (h *UserHandler) UpdatePreferences(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var req struct {
		FCMDeviceToken       string `json:"fcm_device_token"`
		ReceiveNotifications bool   `json:"receive_notifications"`
		ReceiveCritical      bool   `json:"receive_critical"`
		ReceiveWarnings      bool   `json:"receive_warnings"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// user_id is stamped from the verified JWT — never trust the body.
	profile := models.UserProfile{
		UserID:               userID,
		FCMDeviceToken:       req.FCMDeviceToken,
		ReceiveNotifications: req.ReceiveNotifications,
		ReceiveCritical:      req.ReceiveCritical,
		ReceiveWarnings:      req.ReceiveWarnings,
	}

	if err := h.UserStore.UpdateUserPreferences(c.Request.Context(), profile); err != nil {
		slog.Error("UpdatePreferences: store write failed", "user_id", userID, "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update preferences"})
		return
	}
	c.JSON(http.StatusOK, profile)
}
