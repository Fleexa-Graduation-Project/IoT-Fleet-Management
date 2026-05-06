package handlers

import (
	"net/http"
	"strings"

	"github.com/Fleexa-Graduation-Project/Backend/internal/auth"
	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	Cognito *auth.CognitoClient
}

// POST /api/v1/auth/signup
func (h *AuthHandler) SignUp(c *gin.Context) {
	var req struct {
		Username        string `json:"username" binding:"required"`
		Email           string `json:"email" binding:"required,email"`
		Password        string `json:"password" binding:"required,min=8"`
		ConfirmPassword string `json:"confirm_password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Password != req.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"error": "passwords do not match"})
		return
	}
	err := h.Cognito.SignUp(c.Request.Context(), req.Username, strings.ToLower(req.Email), req.Password)
	if err == auth.ErrEmailTaken {
		c.JSON(http.StatusConflict, gin.H{"error": "email already registered"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create account"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "account created successfully"})
}

// POST /api/v1/auth/signin
func (h *AuthHandler) SignIn(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	tokens, err := h.Cognito.SignIn(c.Request.Context(), strings.ToLower(req.Email), req.Password)
	if err == auth.ErrInvalidCredentials {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid email or password"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to sign in"})
		return
	}
	c.JSON(http.StatusOK, tokens)
}

// POST /api/v1/auth/change-password
func (h *AuthHandler) ChangePassword(c *gin.Context) {
	var req struct {
		CurrentPassword string `json:"current_password" binding:"required"`
		NewPassword     string `json:"new_password" binding:"required,min=8"`
		ConfirmPassword string `json:"confirm_new_password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.NewPassword != req.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"error": "passwords do not match"})
		return
	}
	err := h.Cognito.ChangePassword(c.Request.Context(), c.GetString("access_token"), req.CurrentPassword, req.NewPassword)
	if err == auth.ErrInvalidCredentials {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "current password is incorrect"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to change password"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "password changed successfully"})
}

// POST /api/v1/auth/forgot-password
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	var req struct {
		Email string `json:"email" binding:"required,email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	_ = h.Cognito.ForgotPassword(c.Request.Context(), strings.ToLower(req.Email))
	c.JSON(http.StatusOK, gin.H{"message": "if this email is registered, a verification code has been sent"})
}

// POST /api/v1/auth/reset-password
func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var req struct {
		Email           string `json:"email" binding:"required,email"`
		Code            string `json:"code" binding:"required"`
		NewPassword     string `json:"new_password" binding:"required,min=8"`
		ConfirmPassword string `json:"confirm_new_password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.NewPassword != req.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"error": "passwords do not match"})
		return
	}
	err := h.Cognito.ResetPassword(c.Request.Context(), strings.ToLower(req.Email), req.Code, req.NewPassword)
	if err == auth.ErrInvalidCode {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid or expired verification code"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to reset password"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "password reset successfully"})
}

// GET /api/v1/auth/profile
func (h *AuthHandler) GetProfile(c *gin.Context) {
	user, err := h.Cognito.GetUser(c.Request.Context(), c.GetString("access_token"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch profile"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"username": user.Username,
		"email":    user.Email,
	})
}
