package authhandler

import (
	"backend/pkg/model/authmodel"
	"backend/pkg/service/authservice"

	"github.com/gofiber/fiber/v2"
)

type IAuthHandler interface {
	Register(c *fiber.Ctx) error
}
type AuthHandler struct {
	AuthService *authservice.AuthService
}

func NewAuthHandler(authService *authservice.AuthService) *AuthHandler {
	return &AuthHandler{AuthService: authService}
}

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var registerRequest authmodel.RegisterRequest

	if err := c.BodyParser(&registerRequest); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	if err := h.AuthService.Register(&registerRequest); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "User registered successfully",
	})
}
