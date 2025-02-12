package authhandler

import (
	"backend/pkg/service/authservice"

	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct {
	service *authservice.AuthService
}

func NewAuthHandler(service *authservice.AuthService) *AuthHandler {
	return &AuthHandler{service: service}
}

func (h *AuthHandler) LoginHandler(c *fiber.Ctx) error {
	idToken := c.Get("Authorization")
	if idToken == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Missing Authorization Token",
		})	
	}

	// Check Token
	user, err := h.service.Authenticate(idToken)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Successfully logged in",
		"user":    user,
	})
}
