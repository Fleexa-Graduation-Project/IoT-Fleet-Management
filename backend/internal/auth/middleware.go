package auth

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/MicahParks/keyfunc"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
)

var jwks *keyfunc.JWKS

//fetches Cognito's public keys once at startup and caches them
func InitJWKS(ctx context.Context) error {
	region := os.Getenv("AWS_REGION")
	poolID := os.Getenv("COGNITO_USER_POOL_ID")
	url := fmt.Sprintf(
		"https://cognito-idp.%s.amazonaws.com/%s/.well-known/jwks.json",
		region, poolID,
	)
	var err error
	jwks, err = keyfunc.Get(url, keyfunc.Options{
		RefreshInterval:   time.Hour,
		RefreshRateLimit:  5 * time.Minute,
		RefreshUnknownKID: true,
	})
	if err != nil {
		return fmt.Errorf("InitJWKS: url=%s: %w", url, err)
	}
	return nil
}

func Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing authorization header"})
			return
		}
		tokenStr := strings.TrimPrefix(header, "Bearer ")

		token, err := jwt.Parse(tokenStr, jwks.Keyfunc)
		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
			return
		}
		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
			return
		}

		//make sure that it's an access token, not an ID token
		if use, _ := claims["token_use"].(string); use != "access" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "access token required"})
			return
		}

		//access tokens carry the sign-in id in username claim
		c.Set("user_id", claims["sub"])
		c.Set("email", claims["username"])
		c.Set("access_token", tokenStr)
		c.Next()
	}
}
