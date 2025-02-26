package authservice

import (
	"backend/pkg/model/authmodel"
	"errors"

	"gorm.io/gorm"
)

type IAuthService interface {
	Register(registerRequest *authmodel.RegisterRequest) error
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
		Email:    registerRequest.Email,
		Name:     registerRequest.Name,
		Password: registerRequest.Password,
		Phone:    registerRequest.Phone,
		UserType: registerRequest.UserType,
	}

	if err := s.DB.Create(&newUser).Error; err != nil {
		return err
	}

	return nil
}
