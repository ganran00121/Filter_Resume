package authservice

import (
	"errors"
)

type AuthService struct {
	repo *repository.FirebaseRepository
}

func NewAuthService(repo *repository.FirebaseRepository) *AuthService {
	return &AuthService{repo: repo}
}

// Authenticate ตรวจสอบและยืนยันผู้ใช้จาก Firebase
func (s *AuthService) Authenticate(idToken string) (*model.User, error) {
	// Check ID Token
	token, err := s.repo.VerifyIDToken(idToken)
	if err != nil {
		return nil, errors.New("invalid token")
	}

	// Get UID
	userRecord, err := s.repo.GetUser(token.UID)
	if err != nil {
		return nil, err
	}

	// Create User model
	user := &model.User{
		UID:         userRecord.UID,
		Email:       userRecord.Email,
		DisplayName: userRecord.DisplayName,
		PhotoURL:    userRecord.PhotoURL,
		ProviderID:  userRecord.ProviderID,
	}

	return user, nil
}
