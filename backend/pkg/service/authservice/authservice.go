package authservice

import (
	"backend/pkg/model/authmodel"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt"
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
	result := s.DB.Where("email = ?", email).First(&user) // Find the user by email
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return "", nil, ErrUserNotFound // Use named error
		}
		return "", nil, fmt.Errorf("failed to query user: %w", result.Error) // Wrap other errors
	}

	// Generate JWT token with *all* user information.
	token, err := generateJWTToken(&user) // Pass the entire user object
	if err != nil {
		return "", nil, err
	}

	return token, &user, nil // Return token, user pointer, and error (which is nil on success)
}

// ฟังก์ชันสำหรับการสร้าง JWT Token
func generateJWTToken(user *authmodel.User) (string, error) {
	// กำหนดข้อมูลใน Token
	claims := jwt.MapClaims{
		"user_id":      user.ID,
		"name":         user.Name,
		"email":        user.Email,
		"phone":        user.Phone,
		"user_type":    user.UserType,
		"company_name": user.CompanyName,                      // Handle potential nil pointer
		"exp":          time.Now().Add(time.Hour * 24).Unix(), // Token expires in 24 hours
	}

	// สร้าง JWT Token ด้วยการเข้ารหัส
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	secretKey := []byte("your-secret-key") // ใช้ Secret Key สำหรับการเข้ารหัส

	signedToken, err := token.SignedString(secretKey)
	if err != nil {
		return "", err
	}

	return signedToken, nil
}
