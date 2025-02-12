package authrepo

import (
	"context"

	"firebase.google.com/go/auth"

	firebase "firebase.google.com/go"
	"google.golang.org/api/option"
)

type FirebaseRepository struct {
	authClient *auth.Client
}

func NewFirebaseRepository(credentialsFile string) (*FirebaseRepository, error) {
	opt := option.WithCredentialsFile(credentialsFile)
	firebaseApp, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return nil, err
	}

	authClient, err := firebaseApp.Auth(context.Background())
	if err != nil {
		return nil, err
	}

	return &FirebaseRepository{authClient: authClient}, nil
}

// VerifyIDToken ID Token From Firebase
func (repo *FirebaseRepository) VerifyIDToken(idToken string) (*auth.Token, error) {
	return repo.authClient.VerifyIDToken(context.Background(), idToken)
}

// GetUser From Firebase
func (repo *FirebaseRepository) GetUser(uid string) (*auth.UserRecord, error) {
	return repo.authClient.GetUser(context.Background(), uid)
}
