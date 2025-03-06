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
	ErrOTPMismatch        = errors.New("OTP does not match")
	ErrOTPExpired         = errors.New("OTP has expired")
	ErrOTPAlreadyUsed     = errors.New("OTP has already been used")
)

const (
	otpChars  = "1234567890"
	otpLength = 6
)

type IAuthService interface {
	Register(registerRequest *authmodel.RegisterRequest) error
	Login(email, password string) (string, *authmodel.User, error)
	RequestPasswordReset(email string) error
	VerifyOTP(email, otp string) (*authmodel.User, error)
	ResetPassword(req *authmodel.ResetPasswordRequest) error
	UpdateProfile(userID uint, name, phone *string) error
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

func (s *AuthService) GetUserByID(userID uint) (*authmodel.User, error) {
	var user authmodel.User
	result := s.DB.First(&user, userID)

	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil // Return nil, nil for "not found" - IMPORTANT
		}
		return nil, fmt.Errorf("failed to retrieve user: %w", result.Error)
	}

	return &user, nil
}

// ResetPassword updates the user's password (after request reset verification).
func (s *AuthService) ResetPassword(req *authmodel.ResetPasswordRequest) error {
	var user authmodel.User
	if err := s.DB.Where("email = ?", req.Email).First(&user).Error; err != nil {
		return errors.New("email not found")
	}
	user.Password = req.NewPassword
	if err := s.DB.Save(&user).Error; err != nil {
		return errors.New("failed to update password")
	}
	return nil
}

// UpdateProfile updates the user's profile (name and phone).
func (s *AuthService) UpdateProfile(userID uint, name, phone *string) error {
	// 1. Find the user by ID.
	user, err := s.GetUserByID(userID) // Reuse GetUserByID for consistency and soft-delete handling
	if err != nil {
		return fmt.Errorf("failed to get user by id: %w", err)
	}
	if user == nil {
		return ErrUserNotFound // Consistent error for not found
	}

	// 2. Update fields ONLY if they are provided (not nil).
	tx := s.DB.Begin() // Use a transaction!
	if tx.Error != nil {
		return fmt.Errorf("failed to start transaction: %w", tx.Error)
	}

	defer func() {
		if r := recover(); r != nil {
			tx.Rollback() // Rollback on panic
		}
	}()

	if name != nil {
		user.Name = *name // Dereference the pointer to get the string value
	}
	if phone != nil {
		user.Phone = *phone // Dereference the pointer to get the string value
	}

	// 3. Save the changes (within a transaction).
	if err := tx.Save(user).Error; err != nil { // Update the user
		tx.Rollback() // Rollback on error
		return fmt.Errorf("failed to update profile: %w", err)
	}
	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// VerifyOTP checks the provided OTP against the stored OTP for the user.
// func (s *AuthService) VerifyOTP(email, otp string) (*authmodel.User, error) {
// 	var user authmodel.User
// 	result := s.DB.Where("email = ?", email).First(&user)
// 	if result.Error != nil {
// 		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
// 			return nil, ErrUserNotFound // Consistent error
// 		}
// 		return nil, fmt.Errorf("failed to retrieve user: %w", result.Error)
// 	}

// 	// Check if OTP is set, not expired, and not used.
// 	if user.OTP == nil || *user.OTP != otp || time.Now().After(*user.OTPExpiry) || user.OTPUsed {
// 		if user.OTP == nil {
// 			return nil, ErrUserNotFound // No OTP, treat as user not found (for security)
// 		} else if *user.OTP != otp {
// 			return nil, ErrOTPMismatch
// 		} else if time.Now().After(*user.OTPExpiry) {
// 			return nil, ErrOTPExpired
// 		} else {
// 			return nil, ErrOTPAlreadyUsed
// 		}

// 	}

// 	return &user, nil
// }

// generateOTP generates a random 6-digit OTP.
// func generateOTP(length int) (string, error) {
// 	otp := make([]byte, length)
// 	for i := 0; i < length; i++ {
// 		num, err := rand.Int(rand.Reader, big.NewInt(int64(len(otpChars))))
// 		if err != nil {
// 			return "", err
// 		}
// 		otp[i] = otpChars[num.Int64()]
// 	}
// 	return string(otp), nil
// }

// sendOTPEmail sends the OTP to the user's email address.
// func sendOTPEmail(email, otp string) error {
// 	from := os.Getenv("EMAIL_FROM")
// 	pass := os.Getenv("EMAIL_PASS")
// 	if from == "" || pass == "" {
// 		return fmt.Errorf("EMAIL_FROM and EMAIL_PASS environment variables must be set")
// 	}

// 	// Construct the email message.
// 	msg := []byte(fmt.Sprintf("To: %s\r\n"+
// 		"Subject: Password Reset OTP\r\n"+
// 		"\r\n"+
// 		"Your OTP for password reset is: %s\r\n", email, otp))

// 	// SMTP server settings.  Replace with your actual settings.
// 	smtpHost := "smtp.gmail.com" // Example: Gmail
// 	smtpPort := "587"

// 	// Authentication information.
// 	auth := smtp.PlainAuth("", from, pass, smtpHost)

// 	// Send the email.
// 	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, from, []string{email}, msg)
// 	if err != nil {
// 		return fmt.Errorf("failed to send email: %w", err)
// 	}

// 	return nil
// }
