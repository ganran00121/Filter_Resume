package authhandler

import (
	"backend/pkg/model/authmodel"
	"backend/pkg/service/authservice"
	"errors"

	"github.com/gofiber/fiber/v2"
)

type IAuthHandler interface {
	Register(c *fiber.Ctx) error
	Login(c *fiber.Ctx) error
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

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req authmodel.LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "cannot parse login request",
		})
	}

	// Call the service, which now returns both the token and the user
	token, user, err := h.AuthService.Login(req.Email, req.Password)
	if err != nil {
		// Handle service errors (e.g., user not found, invalid credentials)
		if errors.Is(err, authservice.ErrUserNotFound) {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "User not found"})
		} else if errors.Is(err, authservice.ErrInvalidCredentials) {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid credentials"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if user == nil { //Very important to check if user == nil
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "user not found"})
	}

	type UserResponse struct { //Define a struct that represents User response
		ID          uint    `json:"id"`
		Name        string  `json:"name"`
		Email       string  `json:"email"`
		Phone       string  `json:"phone"`
		UserType    string  `json:"user_type"`
		CompanyName *string `json:"company_name,omitempty"`
	}

	responseUser := UserResponse{
		ID:          user.ID,
		Name:        user.Name,
		Email:       user.Email,
		Phone:       user.Phone,
		UserType:    user.UserType,
		CompanyName: user.CompanyName,
	}
	response := fiber.Map{
		"message": "User logged in successfully",
		"token":   token,
		"user":    responseUser, // Include the user data (excluding the password)
	}

	return c.Status(fiber.StatusOK).JSON(response)
}
