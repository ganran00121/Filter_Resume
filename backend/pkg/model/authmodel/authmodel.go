package authmodel

type User struct {
	UID         string `json:"uid"`
	Email       string `json:"email"`
	DisplayName string `json:"displayName"`
	PhotoURL    string `json:"photoURL"`
	ProviderID  string `json:"providerID"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type FirebaseResponse struct {
	IDToken string `json:"idToken"`
}
