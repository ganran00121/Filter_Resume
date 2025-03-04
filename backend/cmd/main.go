package main

import (
	"backend/handler/authhandler"
	"backend/handler/jobhandler"
	"backend/pkg/model/authmodel"
	"backend/pkg/model/jobmodel"
	"backend/pkg/pdfextractor"
	"backend/pkg/service/authservice"
	"backend/pkg/service/geminiservice"
	"backend/pkg/service/jobservice"
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

	if !db.Migrator().HasTable(&authmodel.User{}) {
		log.Println("Tables do not exist. Running AutoMigrate...")
		err = db.AutoMigrate(
			&authmodel.User{},
			&authmodel.CompanyProfile{},
			&authmodel.Message{},
			&authmodel.Notification{},
			&jobmodel.JobPost{},
			&jobmodel.JobApplication{},
			&jobmodel.SavedJob{},
			&jobmodel.Message{},
		)
		if err != nil {
			log.Fatal("failed to auto migrate:", err)
		}
		log.Println("AutoMigrate completed.")
	} else {
		log.Println("Tables already exist. Skipping AutoMigrate.")
	}
	// mockdata.InsertMockData(db)
	// --- Service Initialization ---
	authService := authservice.NewAuthService(db)
	pdfExtractor := pdfextractor.NewPdfExtractor()

	// Get Gemini API key from environment variable.
	geminiAPIKey := os.Getenv("GEMINI_API_KEY")
	geminiEndpoint := "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="
	geminiService := geminiservice.NewGeminiService(geminiAPIKey, geminiEndpoint) // Inject API Key
	jobService := jobservice.NewJobService(db, pdfExtractor, geminiService)       // Inject PdfExtractor and GeminiService

	// Initialize handlers
	authHandler := authhandler.NewAuthHandler(authService)
	jobHandler := jobhandler.NewJobHandler(jobService)

	routes.RegisterRoutes(app, authHandler, jobHandler)

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.SendStatus(fiber.StatusOK)
	})

	log.Printf("Server is running on port %s", os.Getenv("PORT"))
	if err := app.Listen(fmt.Sprintf(":%s", os.Getenv("PORT"))); err != nil {
		log.Fatal(err)
	}
}
