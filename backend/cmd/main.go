package main

import (
	"fmt"
	"log"
	"os"
	"../pkg/repository/authrepo"
	"../pkg/service/authservice"
	"../handler/authhandler"
	firebase "firebase.google.com/go"
	"github.com/gofiber/fiber/v3"
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

	firebaseRepo, err := repository.NewFirebaseRepository(credentialsFile)
	if err != nil {
		log.Fatalf("Error initializing Firebase Repository: %v", err)
	}

	authService := service.NewAuthService(firebaseRepo)

	// สร้าง AuthHandler
	authHandler := handler.NewAuthHandler(authService)

	// Route สำหรับ login
	app.Get("/login", authHandler.LoginHandler)
	app.Get("/health", func(c fiber.Ctx) error {
		return c.SendStatus(fiber.StatusOK)
	})

	log.Printf("Server is running on port %s", os.Getenv("PORT"))
	if err := app.Listen(fmt.Sprintf(":%s", os.Getenv("PORT"))); err != nil {
		log.Fatal(err)
	}
}