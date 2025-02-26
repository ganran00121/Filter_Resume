package routes

import (
	"backend/handler/authhandler"

	"github.com/gofiber/fiber/v2"
)

func RegisterAuthRoutes(app *fiber.App, authHandler *authhandler.AuthHandler) {
	authGroup := app.Group("/auth")

	authGroup.Post("/register", authHandler.Register)
}
