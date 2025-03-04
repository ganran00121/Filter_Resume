// middleware/auth.go
package middleware

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5" // CORRECT IMPORT: /v5
)

// AuthMiddleware is a basic JWT authentication middleware.
func AuthMiddleware(c *fiber.Ctx) error {
	authHeader := c.Get("Authorization") // Get the Authorization header
	if authHeader == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Authorization header is required"})
	}

	// Check if the header starts with "Bearer "
	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid authorization format"})
	}

	tokenString := parts[1] // Get the token part

	// Parse the token.
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Validate the signing method. VERY IMPORTANT!
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		// Get secret key from environment
		secretKey := os.Getenv("JWT_SECRET_KEY")
		if secretKey == "" {
			return nil, fmt.Errorf("JWT_SECRET_KEY environment variable not set")
		}
		return []byte(secretKey), nil // Return the secret key.  MUST be []byte
	})

	if err != nil {
		if errors.Is(err, jwt.ErrTokenMalformed) {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Malformed token"})
		} else if errors.Is(err, jwt.ErrTokenExpired) || errors.Is(err, jwt.ErrTokenNotValidYet) {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Token expired or not yet valid"})
		} else {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid token"})
		}
	}

	// Check if the token is valid.
	//Check claims and store it to context
	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		userID, ok := claims["user_id"].(float64)
		if !ok {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "user_id claim is missing or invalid"})
		}
		userType, ok := claims["user_type"].(string) // Extract user_type
		if !ok {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "user_type claim is missing or invalid"})

		}

		c.Locals("user", token)          // Store the entire token (for other claims)
		c.Locals("userID", uint(userID)) // Store user ID as uint
		c.Locals("userType", userType)   // Store user type
		return c.Next()
	}

	return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid token"})
}
