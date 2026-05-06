package auth

import (
	"context"
	"errors"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	cognitosvc "github.com/aws/aws-sdk-go-v2/service/cognitoidentityprovider"
	"github.com/aws/aws-sdk-go-v2/service/cognitoidentityprovider/types"
)

type CognitoClient struct {
	svc        *cognitosvc.Client
	clientID   string
	userPoolID string
}

func NewCognitoClient(cfg aws.Config) (*CognitoClient, error) {
	clientID := os.Getenv("COGNITO_CLIENT_ID")
	userPoolID := os.Getenv("COGNITO_USER_POOL_ID")
	if clientID == "" || userPoolID == "" {
		return nil, fmt.Errorf("COGNITO_CLIENT_ID and COGNITO_USER_POOL_ID env vars required")
	}
	return &CognitoClient{
		svc:        cognitosvc.NewFromConfig(cfg),
		clientID:   clientID,
		userPoolID: userPoolID,
	}, nil
}

// SignUp creates a new user, auto-confirms it, and marks email as verified
// so ForgotPassword can deliver the OTP code without a separate confirmation step.
func (c *CognitoClient) SignUp(ctx context.Context, username, email, password string) error {
	_, err := c.svc.SignUp(ctx, &cognitosvc.SignUpInput{
		ClientId: aws.String(c.clientID),
		Username: aws.String(email),
		Password: aws.String(password),
		UserAttributes: []types.AttributeType{
			{Name: aws.String("email"), Value: aws.String(email)},
			{Name: aws.String("name"), Value: aws.String(username)},
		},
	})
	if err != nil {
		var exists *types.UsernameExistsException
		if errors.As(err, &exists) {
			return ErrEmailTaken
		}
		return fmt.Errorf("SignUp: email=%s: %w", email, err)
	}

	if _, err = c.svc.AdminConfirmSignUp(ctx, &cognitosvc.AdminConfirmSignUpInput{
		UserPoolId: aws.String(c.userPoolID),
		Username:   aws.String(email),
	}); err != nil {
		return fmt.Errorf("SignUp confirm: email=%s: %w", email, err)
	}

	// email_verified=true is required for ForgotPassword to deliver the OTP
	if _, err = c.svc.AdminUpdateUserAttributes(ctx, &cognitosvc.AdminUpdateUserAttributesInput{
		UserPoolId: aws.String(c.userPoolID),
		Username:   aws.String(email),
		UserAttributes: []types.AttributeType{
			{Name: aws.String("email_verified"), Value: aws.String("true")},
		},
	}); err != nil {
		return fmt.Errorf("SignUp verify email: email=%s: %w", email, err)
	}
	return nil
}

func (c *CognitoClient) SignIn(ctx context.Context, email, password string) (*AuthTokens, error) {
	out, err := c.svc.InitiateAuth(ctx, &cognitosvc.InitiateAuthInput{
		AuthFlow: types.AuthFlowTypeUserPasswordAuth,
		ClientId: aws.String(c.clientID),
		AuthParameters: map[string]string{
			"USERNAME": email,
			"PASSWORD": password,
		},
	})
	if err != nil {
		var notAuth *types.NotAuthorizedException
		var notFound *types.UserNotFoundException
		if errors.As(err, &notAuth) || errors.As(err, &notFound) {
			return nil, ErrInvalidCredentials
		}
		return nil, fmt.Errorf("SignIn: email=%s: %w", email, err)
	}
	return &AuthTokens{
		AccessToken:  aws.ToString(out.AuthenticationResult.AccessToken),
		IDToken:      aws.ToString(out.AuthenticationResult.IdToken),
		RefreshToken: aws.ToString(out.AuthenticationResult.RefreshToken),
	}, nil
}

func (c *CognitoClient) ChangePassword(ctx context.Context, accessToken, currentPassword, newPassword string) error {
	_, err := c.svc.ChangePassword(ctx, &cognitosvc.ChangePasswordInput{
		AccessToken:      aws.String(accessToken),
		PreviousPassword: aws.String(currentPassword),
		ProposedPassword: aws.String(newPassword),
	})
	if err != nil {
		var notAuth *types.NotAuthorizedException
		if errors.As(err, &notAuth) {
			return ErrInvalidCredentials
		}
		return fmt.Errorf("ChangePassword: %w", err)
	}
	return nil
}

func (c *CognitoClient) ForgotPassword(ctx context.Context, email string) error {
	_, err := c.svc.ForgotPassword(ctx, &cognitosvc.ForgotPasswordInput{
		ClientId: aws.String(c.clientID),
		Username: aws.String(email),
	})
	if err != nil {
		return fmt.Errorf("ForgotPassword: email=%s: %w", email, err)
	}
	return nil
}

// ResetPassword verifies the OTP code and sets the new password atomically via Cognito.
func (c *CognitoClient) ResetPassword(ctx context.Context, email, code, newPassword string) error {
	_, err := c.svc.ConfirmForgotPassword(ctx, &cognitosvc.ConfirmForgotPasswordInput{
		ClientId:         aws.String(c.clientID),
		Username:         aws.String(email),
		ConfirmationCode: aws.String(code),
		Password:         aws.String(newPassword),
	})
	if err != nil {
		var codeMismatch *types.CodeMismatchException
		var expired *types.ExpiredCodeException
		if errors.As(err, &codeMismatch) || errors.As(err, &expired) {
			return ErrInvalidCode
		}
		return fmt.Errorf("ResetPassword: email=%s: %w", email, err)
	}
	return nil
}

func (c *CognitoClient) GetUser(ctx context.Context, accessToken string) (*UserInfo, error) {
	out, err := c.svc.GetUser(ctx, &cognitosvc.GetUserInput{
		AccessToken: aws.String(accessToken),
	})
	if err != nil {
		return nil, fmt.Errorf("GetUser: %w", err)
	}
	info := &UserInfo{}
	for _, attr := range out.UserAttributes {
		switch aws.ToString(attr.Name) {
		case "sub":
			info.UserID = aws.ToString(attr.Value)
		case "email":
			info.Email = aws.ToString(attr.Value)
		case "name":
			info.Username = aws.ToString(attr.Value)
		}
	}
	return info, nil
}

type AuthTokens struct {
	AccessToken  string `json:"access_token"`
	IDToken      string `json:"id_token"`
	RefreshToken string `json:"refresh_token"`
}

type UserInfo struct {
	UserID   string
	Username string
	Email    string
}

var (
	ErrEmailTaken         = errors.New("email already registered")
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrInvalidCode        = errors.New("invalid or expired verification code")
)
