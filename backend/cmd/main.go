package main

import (
	"backend/handler/authhandler"
	"backend/pkg/model/authmodel"
	"backend/pkg/service/authservice"
	"backend/routes"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go"
	"github.com/gofiber/fiber/v2"
	"github.com/joho/godotenv"
	"github.com/pkg/errors"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var firebaseApp *firebase.App

func main() {
	app := fiber.New()

	err := godotenv.Load(".env")
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	db, err := gorm.Open(mysql.New(mysql.Config{
		DSN:                       os.Getenv("DATABASE_CONNECTION_STRING"),
		DefaultStringSize:         256,
		DisableDatetimePrecision:  true,
		DontSupportRenameIndex:    true,
		DontSupportRenameColumn:   true,
		SkipInitializeWithVersion: false,
	}), &gorm.Config{
		SkipDefaultTransaction: true,
	})

	if err != nil {
		errorWrapper := errors.Wrap(err, "database connection")
		log.Fatal(errorWrapper)
	}

	db.AutoMigrate(&authmodel.User{}, &authmodel.CompanyProfile{}, &authmodel.JobApplication{}, &authmodel.JobPost{}, authmodel.SavedJob{}, &authmodel.Message{}, &authmodel.Notification{})
	// mockdata.InsertMockData(db)
	//สร้าง AuthService
	authService := authservice.NewAuthService(db)

	// สร้าง AuthHandler
	authHandler := authhandler.NewAuthHandler(authService)

	routes.RegisterAuthRoutes(app, authHandler)

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.SendStatus(fiber.StatusOK)
	})

	log.Printf("Server is running on port %s", os.Getenv("PORT"))
	if err := app.Listen(fmt.Sprintf(":%s", os.Getenv("PORT"))); err != nil {
		log.Fatal(err)
	}
}
