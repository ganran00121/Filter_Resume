package main

import (
	"backend/handler/authhandler"
	"backend/pkg/repository/authrepo"
	"backend/pkg/service/authservice"
	"backend/routes"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go"
	"github.com/gofiber/fiber/v2"
	"github.com/joho/godotenv"
)

var firebaseApp *firebase.App

func main() {
	app := fiber.New()
	//load .env
	err := godotenv.Load(".env")
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	credentialsFile := "flitter-resume-firebase-adminsdk-fbsvc-80dab766cc.json"

	firebaseRepo, err := authrepo.NewFirebaseRepository(credentialsFile)
	if err != nil {
		log.Fatalf("Error initializing Firebase Repository: %v", err)
	}

	authService := authservice.NewAuthService(firebaseRepo)

	// สร้าง AuthHandler
	authHandler := authhandler.NewAuthHandler(authService)

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.SendStatus(fiber.StatusOK)
	})

	routes.RegisterAuthRoutes(app, *authHandler)

	log.Printf("Server is running on port %s", os.Getenv("PORT"))
	if err := app.Listen(fmt.Sprintf(":%s", os.Getenv("PORT"))); err != nil {
		log.Fatal(err)
	}
}
