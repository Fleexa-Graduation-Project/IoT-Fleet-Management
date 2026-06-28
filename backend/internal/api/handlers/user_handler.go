package handlers

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/Fleexa-Graduation-Project/Backend/internal/users"
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
		HardwareID           string `json:"hardware_id"`
		FCMToken             string `json:"fcm_token"`
		ReceiveNotifications bool   `json:"receive_notifications"`
		ReceiveCritical      bool   `json:"receive_critical"`
		ReceiveWarnings      bool   `json:"receive_warnings"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// read first to preserve tokens from other devices
	profile, err := h.UserStore.GetUserProfile(c.Request.Context(), userID)
	if err != nil {
		slog.Error("UpdatePreferences: failed to read profile", "user_id", userID, "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load preferences"})
		return
	}

	profile.ReceiveNotifications = req.ReceiveNotifications
	profile.ReceiveCritical = req.ReceiveCritical
	profile.ReceiveWarnings = req.ReceiveWarnings

	// hardware_id present + token non-empty → register; empty token → unregister (logout)
	if req.HardwareID != "" {
		if req.FCMToken != "" {
			if profile.FCMDeviceTokens == nil {
				profile.FCMDeviceTokens = make(map[string]string)
			}
			profile.FCMDeviceTokens[req.HardwareID] = req.FCMToken
		} else {
			delete(profile.FCMDeviceTokens, req.HardwareID)
		}
	}

	if err := h.UserStore.UpdateUserPreferences(c.Request.Context(), profile); err != nil {
		slog.Error("UpdatePreferences: store write failed", "user_id", userID, "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update preferences"})
		return
	}
	c.JSON(http.StatusOK, profile)
}
