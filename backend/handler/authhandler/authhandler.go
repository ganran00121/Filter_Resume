package authhandler

import (
	"github.com/gofiber/fiber/v3"
)

type AuthHandler struct {
	service *service.AuthService
}

func NewAuthHandler(service *service.AuthService) *AuthHandler {
	return &AuthHandler{service: service}
}

func (h *AuthHandler) LoginHandler(c fiber.Ctx) error {
	idToken := c.Get("Authorization")
	if idToken == "" {
		return c.Bind().Body(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Missing Authorization Token",
		})
	}

	// Check Token
	user, err := h.service.Authenticate(idToken)
	if err != nil {
		return c.Bind().Body(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Successfully logged in",
		"user":    user,
	})
}
