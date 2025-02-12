package authhandler

import (
	"backend/pkg/model/authmodel"
	"backend/pkg/service/authservice"
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"os"

	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct {
	service *authservice.AuthService
}

func NewAuthHandler(service *authservice.AuthService) *AuthHandler {
	return &AuthHandler{service: service}
}

func (h *AuthHandler) LoginHandler(c *fiber.Ctx) error {
	// อ่านข้อมูล email และ password
	var req authmodel.LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	// ส่งข้อมูลไปที่ Firebase Authentication
	idToken, err := signInWithPassword(req.Email, req.Password)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	// ใช้ idToken เพื่อตรวจสอบผู้ใช้ในระบบ
	user, err := h.service.Authenticate(idToken)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	// ส่ง response กลับ
	return c.JSON(fiber.Map{
		"message": "Successfully logged in",
		"user":    user,
		"token":   idToken,
	})
}

// ฟังก์ชันส่ง request ไป Firebase Authentication
func signInWithPassword(email, password string) (string, error) {
	payload := map[string]interface{}{
		"email":             email,
		"password":          password,
		"returnSecureToken": true,
	}

	jsonPayload, _ := json.Marshal(payload)

	resp, err := http.Post(os.Getenv("URL_TOKEN"), "application/json", bytes.NewBuffer(jsonPayload))
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", errors.New("invalid email or password")
	}

	var firebaseResp authmodel.FirebaseResponse
	if err := json.NewDecoder(resp.Body).Decode(&firebaseResp); err != nil {
		return "", err
	}

	return firebaseResp.IDToken, nil
}
