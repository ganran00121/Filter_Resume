package authservice

import (
	"backend/pkg/model/authmodel"
	"backend/pkg/repository/authrepo"
	"errors"
)

type AuthService struct {
	repo *authrepo.FirebaseRepository
}

func NewAuthService(repo *authrepo.FirebaseRepository) *AuthService {
	return &AuthService{repo: repo}
}

func (s *AuthService) Authenticate(idToken string) (*authmodel.User, error) {
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
	user := &authmodel.User{
		UID:         userRecord.UID,
		Email:       userRecord.Email,
		DisplayName: userRecord.DisplayName,
		PhotoURL:    userRecord.PhotoURL,
		ProviderID:  userRecord.ProviderID,
	}

	return user, nil
}
