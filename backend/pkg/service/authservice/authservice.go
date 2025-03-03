package authservice

import (
	"backend/pkg/model/authmodel"
	"errors"
	"time"

	"github.com/golang-jwt/jwt"
	"gorm.io/gorm"
)

type IAuthService interface {
	Register(registerRequest *authmodel.RegisterRequest) error
	Login(loginRequest *authmodel.LoginRequest) (string, error)
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

func (s *AuthService) Login(loginRequest *authmodel.LoginRequest) (string, error) {
	var user authmodel.User

	// ค้นหาผู้ใช้จากฐานข้อมูลตามอีเมล
	if err := s.DB.Where("email = ?", loginRequest.Email).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// ถ้าผู้ใช้ไม่พบ
			return "", errors.New("user not found")
		}
		// ถ้ามีข้อผิดพลาดในการดึงข้อมูลจากฐานข้อมูล
		return "", err
	}

	//เปรียบเทียบรหัสผ่านตอน Hash
	// err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(request.Password))
	// if err != nil {
	// 	// ถ้ารหัสผ่านไม่ถูกต้อง
	// 	return "", errors.New("invalid password")
	// }

	// สร้าง JWT token
	token, err := generateJWTToken(user.ID)
	if err != nil {
		return "", err
	}

	return token, nil
}

// ฟังก์ชันสำหรับการสร้าง JWT Token
func generateJWTToken(userID uint) (string, error) {
	// กำหนดข้อมูลใน Token
	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(time.Hour * 24).Unix(), // กำหนดเวลา Expire เป็น 1 วัน
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
