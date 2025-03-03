package routes

import (
	"backend/handler/authhandler"
	"backend/handler/jobhandler"

	"github.com/gofiber/fiber/v2"
)

// RegisterAuthRoutes sets up routes for authentication.
func RegisterAuthRoutes(app *fiber.App, authHandler *authhandler.AuthHandler) {
	authGroup := app.Group("/auth")
	authGroup.Post("/register", authHandler.Register) // POST /auth/register
	authGroup.Post("/login", authHandler.Login)       // POST /auth/login
}

// RegisterJobRoutes sets up routes for job-related operations.
func RegisterJobRoutes(app *fiber.App, jobHandler *jobhandler.JobHandler) {
	jobGroup := app.Group("/api/jobs")

	// Job Post Routes
	jobGroup.Post("/", jobHandler.CreateJobPost)                          // POST /api/jobs
	jobGroup.Get("/:id", jobHandler.GetJobPost)                           // GET /api/jobs/:id
	jobGroup.Put("/:id", jobHandler.UpdateJobPost)                        // PUT /api/jobs/:id
	jobGroup.Delete("/:id", jobHandler.DeleteJobPost)                     // DELETE /api/jobs/:id
	jobGroup.Get("/", jobHandler.ListJobPosts)                            // GET /api/jobs
	jobGroup.Get("/company/:companyId", jobHandler.ListJobPostsByCompany) // GET /api/jobs/company/:companyId  (Note: companyId is actually UserId)
	jobGroup.Get("/open", jobHandler.ListOpenJobPosts)                    // GET /api/jobs/open
	jobGroup.Get("/closed", jobHandler.ListClosedJobPosts)                // GET /api/jobs/closed

	// Job Application Routes
	jobGroup.Post("/:jobId/apply", jobHandler.CreateJobApplication)                   // POST /api/jobs/:jobId/apply
	jobGroup.Get("/applications/:id", jobHandler.GetJobApplication)                   // GET /api/jobs/applications/:id
	jobGroup.Put("/applications/:id", jobHandler.UpdateJobApplication)                // PUT /api/jobs/applications/:id
	jobGroup.Get("/:jobId/applications", jobHandler.ListJobApplicationsForJob)        // GET /api/jobs/:jobId/applications
	jobGroup.Get("/user/:userId/applications", jobHandler.ListJobApplicationsForUser) // GET /api/jobs/user/:userId/applications
	jobGroup.Get("/applications", jobHandler.ListJobApplications)                     // GET /api/jobs/applications?status=pending  (and other status values, or no status for all)

	// Saved Job Routes
	jobGroup.Post("/user/:userId/save/:jobId", jobHandler.SaveJob)           // POST /api/jobs/user/:userId/save/:jobId
	jobGroup.Delete("/user/:userId/unsave/:jobId", jobHandler.UnsaveJob)     // DELETE /api/jobs/user/:userId/unsave/:jobId
	jobGroup.Get("/user/:userId/saved", jobHandler.ListSavedJobs)            // GET /api/jobs/user/:userId/saved
	jobGroup.Get("/user/:userId/saved/:jobId", jobHandler.CheckIfJobIsSaved) // GET /api/jobs/user/:userId/saved/:jobId
}

// RegisterRoutes sets up all routes for the application.  This is the function you call in main.go.
func RegisterRoutes(app *fiber.App, authHandler *authhandler.AuthHandler, jobHandler *jobhandler.JobHandler) {
	RegisterAuthRoutes(app, authHandler)
	RegisterJobRoutes(app, jobHandler)
}
