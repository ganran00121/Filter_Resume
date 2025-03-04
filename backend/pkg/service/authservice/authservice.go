package authservice

import (
	"backend/pkg/model/authmodel"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserNotFound       = errors.New("user not found")
)

type IAuthService interface {
	Register(registerRequest *authmodel.RegisterRequest) error
	Login(email, password string) (string, *authmodel.User, error)
}
type AuthService struct {
	DB *gorm.DB
}

func NewAuthService(db *gorm.DB) *AuthService {
	return &AuthService{DB: db}
}

func (s *AuthService) Register(registerRequest *authmodel.RegisterRequest) error {

	var User authmodel.RegisterRequest
	if err := s.DB.Where("email = ?", registerRequest.Email).First(&User).Error; err == nil {
		return errors.New("user already exists")
	}

	newUser := authmodel.User{
		Email:       registerRequest.Email,
		Name:        registerRequest.Name,
		Password:    registerRequest.Password,
		Phone:       registerRequest.Phone,
		UserType:    registerRequest.UserType,
		CompanyName: registerRequest.CompanyName,
	}

	if err := s.DB.Create(&newUser).Error; err != nil {
		return err
	}

	return nil
}

func (s *AuthService) Login(email, password string) (string, *authmodel.User, error) {
	var user authmodel.User
	result := s.DB.Where("email = ?", email).First(&user)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return "", nil, ErrUserNotFound
		}
		return "", nil, fmt.Errorf("failed to query user: %w", result.Error)
	}

	// Generate JWT token
	token, err := generateJWTToken(&user) // Pass the entire user object
	if err != nil {
		return "", nil, err
	}

	return token, &user, nil // Return the token, user and nil error on success
}

func generateJWTToken(user *authmodel.User) (string, error) {
	claims := jwt.MapClaims{
		"user_id":      user.ID, // Include user ID
		"name":         user.Name,
		"email":        user.Email,
		"phone":        user.Phone,
		"user_type":    user.UserType,
		"company_name": user.CompanyName,                      // Handle potential nil pointer
		"exp":          time.Now().Add(time.Hour * 24).Unix(), // Token expires in 24 hours
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Load secret key from environment variable.
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		return "", fmt.Errorf("JWT_SECRET_KEY environment variable not set")
	}

	signedToken, err := token.SignedString([]byte(secretKey)) // Sign the token
	if err != nil {
		return "", fmt.Errorf("failed to sign token: %w", err) // More specific error
	}

	return signedToken, nil
}
