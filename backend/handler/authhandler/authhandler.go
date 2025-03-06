package authhandler

import (
	"backend/pkg/model/authmodel"
	"backend/pkg/service/authservice"
	"errors"
	"fmt"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

type IAuthHandler interface {
	Register(c *fiber.Ctx) error
	Login(c *fiber.Ctx) error
	GetUserProfile(c *fiber.Ctx) error
	RequestPasswordReset(c *fiber.Ctx) error
	ResetPassword(c *fiber.Ctx) error
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

// GetUserProfile handles GET /api/user/profile
func (h *AuthHandler) GetUserProfile(c *fiber.Ctx) error {
	// 1. Get User ID from JWT (Authentication).
	userID, err := getUserIDFromToken(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	// 2. Call the AuthService to get the user.
	user, err := h.AuthService.GetUserByID(userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve user profile"})
	}

	// 3. Handle User Not Found.
	if user == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
	}
	// 4. Create a Response Structure (DTO - Data Transfer Object).  This is crucial for security and flexibility.
	type UserProfileResponse struct {
		ID           uint    `json:"id"`
		Name         string  `json:"name"`
		Email        string  `json:"email"`
		Phone        *string `json:"phone,omitempty"` // Optional field
		UserType     string  `json:"user_type"`
		ProfileImage *string `json:"profile_image,omitempty"`
		CompanyName  *string `json:"company_name,omitempty"`
	}

	// 5. Map the User data to the Response Structure.
	response := UserProfileResponse{
		ID:           user.ID,
		Name:         user.Name,
		Email:        user.Email,
		Phone:        &user.Phone, // Directly assign (it's already a pointer)
		UserType:     user.UserType,
		ProfileImage: user.ProfileImage,
		CompanyName:  user.CompanyName,
	}

	// 6. Return the Response.
	return c.Status(fiber.StatusOK).JSON(response)
}

func (h *AuthHandler) ResetPassword(c *fiber.Ctx) error {
	var req authmodel.ResetPasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	if err := h.AuthService.ResetPassword(&req); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "Password reset successful"})
}

// Helper function to get user id from jwt token
func getUserIDFromToken(c *fiber.Ctx) (uint, error) {
	user := c.Locals("user") // Get the user object from context (set by middleware)
	if user == nil {
		return 0, fmt.Errorf("no user in context")
	}

	token, ok := user.(*jwt.Token) // Assert to *jwt.Token  <-- CORRECT TYPE
	if !ok {
		return 0, fmt.Errorf("invalid token type")
	}

	claims, ok := token.Claims.(jwt.MapClaims) // Get the claims
	if !ok {
		return 0, fmt.Errorf("invalid claims type")
	}

	// IMPORTANT:  Always validate the data type before using it!
	userIDFloat, ok := claims["user_id"].(float64) // JWT IDs are often floats
	if !ok {
		return 0, fmt.Errorf("invalid user ID format in token")
	}
	userID := uint(userIDFloat) // Convert to uint

	return userID, nil
}
