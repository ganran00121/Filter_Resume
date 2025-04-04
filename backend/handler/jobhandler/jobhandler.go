package jobhandler

import (
	"backend/pkg/model/jobmodel"
	"backend/pkg/service/jobservice"
	"bytes"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

type IJobHandler interface {
	CreateJobPost(c *fiber.Ctx) error
	GetJobPost(c *fiber.Ctx) error
	UpdateJobPost(c *fiber.Ctx) error
	DeleteJobPost(c *fiber.Ctx) error
	ListJobPosts(c *fiber.Ctx) error
	ListJobPostsByCompany(c *fiber.Ctx) error
	ListOpenJobPosts(c *fiber.Ctx) error
	ListClosedJobPosts(c *fiber.Ctx) error
	CreateJobApplication(c *fiber.Ctx) error
	GetJobApplication(c *fiber.Ctx) error
	UpdateJobApplication(c *fiber.Ctx) error
	ListJobApplicationsForJob(c *fiber.Ctx) error
	ListJobApplicationsForUser(c *fiber.Ctx) error
	ListJobApplications(c *fiber.Ctx) error
	ListJobPostsByUserID(c *fiber.Ctx) error // New handler method

	SaveJob(c *fiber.Ctx) error
	UnsaveJob(c *fiber.Ctx) error
	ListSavedJobs(c *fiber.Ctx) error
	CheckIfJobIsSaved(c *fiber.Ctx) error
}

type JobHandler struct {
	JobService jobservice.IJobService
}

func NewJobHandler(jobService jobservice.IJobService) *JobHandler {
	return &JobHandler{JobService: jobService}
}

const (
	errInvalidJobID    = "Invalid job ID"
	errJobPostNotFound = "Job post not found"
	errUnauthorized    = "Unauthorized"
	errDeleteJobPost   = "Failed to delete job post"
)

// Job Post Handlers

// CreateJobPost handles POST /api/jobs
func (h *JobHandler) CreateJobPost(c *fiber.Ctx) error {
	var jobPost jobmodel.JobPost
	if err := c.BodyParser(&jobPost); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	if err := h.JobService.CreateJobPost(&jobPost); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create job post"})
	}

	return c.Status(fiber.StatusCreated).JSON(jobPost)
}

// GetJobPost handles GET /api/jobs/:id
func (h *JobHandler) GetJobPost(c *fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID7"})
	}

	jobPost, err := h.JobService.GetJobPostByID(uint(id))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job post"})
	}
	if jobPost == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job post not found"})
	}

	return c.Status(fiber.StatusOK).JSON(jobPost)
}

// UpdateJobPost handles PUT /api/jobs/:id
func (h *JobHandler) UpdateJobPost(c *fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}

	var jobPost jobmodel.JobPost
	if err := c.BodyParser(&jobPost); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	jobPost.ID = uint(id)

	if err := h.JobService.UpdateJobPost(&jobPost); err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job post not found"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update job post"})
	}

	return c.Status(fiber.StatusOK).JSON(jobPost)
}

// DeleteJobPost handles DELETE /api/jobs/:id
func (h *JobHandler) DeleteJobPost(c *fiber.Ctx) error {
	jobID, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": errInvalidJobID})
	}

	// Get the user ID from the JWT token.
	userID, err := getUserIDFromToken(c) // You'll need this helper function
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": errUnauthorized})
	}

	// Call the service layer, passing both the job ID and user ID.
	if err := h.JobService.DeleteJobPost(uint(jobID), userID); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": errJobPostNotFound})
		} else if errors.Is(err, jobservice.ErrUnauthorized) { // Check for ErrUnauthorized
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": errUnauthorized}) // Or 403 Forbidden
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": errDeleteJobPost})
	}

	// Return a success message with 200 OK
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "Job post deleted successfully"})
}

// ListJobPosts handles GET /api/jobs
func (h *JobHandler) ListJobPosts(c *fiber.Ctx) error {
	jobPosts, err := h.JobService.ListJobPosts()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job posts"})
	}

	// Create a response structure that includes the company name and applicant count.
	type Response struct {
		ID             uint    `json:"id"`
		Title          string  `json:"title"`
		Description    string  `json:"description"`
		Location       string  `json:"location"`
		SalaryRange    string  `json:"salary_range"`
		JobPosition    string  `json:"job_position"`
		CompanyName    *string `json:"company_name"` // Use a pointer to handle nil
		Status         bool    `json:"status"`       // Add the Status field
		Quantity       int     `json:"quantity"`
		ApplicantCount int64   `json:"applicant_count"` // Add applicant count
		UserID         uint    `json:"user_id"`
	}

	responseList := make([]Response, 0, len(jobPosts))
	for _, jobPost := range jobPosts {
		// Get the applicant count for EACH job post.
		count, err := h.JobService.CountApplicationsByJobID(jobPost.ID)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve applicant count"})
		}

		// CORRECTED:  Use direct access (Option 1 - Recommended)
		responseList = append(responseList, Response{
			ID:             jobPost.ID,
			Title:          jobPost.Title,
			Description:    jobPost.Description,
			Location:       jobPost.Location,
			SalaryRange:    jobPost.SalaryRange,
			JobPosition:    jobPost.JobPosition,
			CompanyName:    jobPost.User.CompanyName, // Direct access
			Status:         jobPost.Status,           // Include Status
			Quantity:       jobPost.Quantity,
			ApplicantCount: count, // Add the count
			UserID:         jobPost.UserID,
		})
	}

	return c.Status(fiber.StatusOK).JSON(responseList)
}

// ListJobPostsByCompany handles GET /api/jobs/company/:companyId
func (h *JobHandler) ListJobPostsByCompany(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("companyId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}

	jobPosts, err := h.JobService.ListJobPostsByCompanyID(uint(userID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job posts"})
	}
	return c.Status(fiber.StatusOK).JSON(jobPosts)
}

// ListOpenJobPosts handles GET /api/jobs/open
func (h *JobHandler) ListOpenJobPosts(c *fiber.Ctx) error {
	jobPosts, err := h.JobService.ListOpenJobPosts()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve open job posts"})
	}
	return c.Status(fiber.StatusOK).JSON(jobPosts)
}

// ListClosedJobPosts handles GET /api/jobs/closed
func (h *JobHandler) ListClosedJobPosts(c *fiber.Ctx) error {
	jobPosts, err := h.JobService.ListClosedJobPosts()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve closed job posts"})
	}
	return c.Status(fiber.StatusOK).JSON(jobPosts)
}

// Job Application Handlers

// CreateJobApplication handles POST /api/jobs/:jobId/apply
func (h *JobHandler) CreateJobApplication(c *fiber.Ctx) error {
	jobID, err := strconv.ParseUint(c.Params("jobId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}

	// Get the user ID from the JWT token (assuming you have authentication middleware)
	// This is a placeholder.  You MUST get the user ID from your authentication.
	userID, err := getUserIDFromToken(c) // Replace with your actual auth logic
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"}) // Or a better error
	}
	// Parse the multipart form
	form, err := c.MultipartForm()
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid form data"})
	}

	// --- Get resume file ---
	files := form.File["resume"] // "resume" is the *name* of the file input field in your HTML form
	if len(files) == 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "No resume file provided"})
	}
	file := files[0] // Get the first file (you can handle multiple files if needed)

	// Open the file
	resumeFile, err := file.Open()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to open resume file"})
	}
	defer resumeFile.Close()

	// Read the file content into a byte slice
	buf := bytes.NewBuffer(nil)
	if _, err := io.Copy(buf, resumeFile); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to read resume file"})
	}
	fileBytes := buf.Bytes()

	// Create the application object
	application := jobmodel.JobApplication{
		JobID:  uint(jobID),
		UserID: userID,                               // Use the user ID from the token
		Status: jobmodel.JobApplicationStatusPending, // Set initial status to "pending"
	}

	// Call the service to create the application and save the file
	filePath, err := h.JobService.CreateJobApplication(&application, fileBytes)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()}) // Return specific error
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "Application submitted successfully", "resume_file": filePath})
}

// getUserIDFromToken extracts the user ID from the JWT in the request context.
func getUserIDFromToken(c *fiber.Ctx) (uint, error) {
	user := c.Locals("user") // Get the user object from context (set by middleware)
	if user == nil {
		return 0, fmt.Errorf("no user in context")
	}

	token, ok := user.(*jwt.Token) // Assert to *jwt.Token
	if !ok {
		return 0, fmt.Errorf("invalid token type")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
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

// GetJobApplication handles GET /api/jobs/applications/:id
func (h *JobHandler) GetJobApplication(c *fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid application ID"})
	}

	application, err := h.JobService.GetJobApplicationByID(uint(id))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job application"})
	}
	if application == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job application not found"})
	}

	return c.Status(fiber.StatusOK).JSON(application)
}

// UpdateJobApplication handles PUT /api/jobs/applications/:id
func (h *JobHandler) UpdateJobApplication(c *fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid application ID"})
	}

	var application jobmodel.JobApplication
	if err := c.BodyParser(&application); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	application.ID = uint(id)

	if err := h.JobService.UpdateJobApplication(&application); err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job application not found"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update job application"})
	}

	return c.Status(fiber.StatusOK).JSON(application)
}

// ListJobApplicationsForJob handles GET /api/jobs/:jobId/applications
func (h *JobHandler) ListJobApplicationsForJob(c *fiber.Ctx) error {
	jobID, err := strconv.ParseUint(c.Params("jobId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}

	applications, err := h.JobService.ListJobApplicationsByJobID(uint(jobID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job applications"})
	}

	// OPTIONAL: Create a response struct for cleaner output.  This is HIGHLY recommended.
	type ApplicationResponse struct {
		ID             uint      `json:"id"`
		JobID          uint      `json:"job_id"`
		UserID         uint      `json:"user_id"`
		ApplicantName  string    `json:"applicant_name"`  // Get from preloaded User
		ApplicantEmail string    `json:"applicant_email"` // Get from preloaded User
		ResumeFile     string    `json:"resume_file"`
		Status         string    `json:"status"` // Use string for easier handling
		CreatedAt      time.Time `json:"created_at"`
		UpdatedAt      time.Time `json:"updated_at"`
		GeminiSummary  string    `json:"gemini_summary,omitempty"`
		Score          *float64  `json:"score,omitempty"`
	}

	responseList := make([]ApplicationResponse, 0, len(applications))
	for _, app := range applications {
		// Check for preloaded data and nil pointers safely.
		if app.User.ID == 0 {
			// Handle cases where the user isn't preloaded (shouldn't happen, but be defensive).
			fmt.Println("Warning: User not preloaded for application:", app.ID) // Log a warning
			continue                                                            // Or return an error, depending on how critical this is
		}
		responseList = append(responseList, ApplicationResponse{
			ID:             app.ID,
			JobID:          app.JobID,
			UserID:         app.UserID,
			ApplicantName:  app.User.Name,  // Get name from preloaded User
			ApplicantEmail: app.User.Email, // Get email from preloaded User
			ResumeFile:     app.ResumeFile,
			Status:         string(app.Status), // Convert to string
			CreatedAt:      app.CreatedAt,
			UpdatedAt:      app.UpdatedAt,
			GeminiSummary:  app.GeminiSummary,
			Score:          app.Score,
		})
	}

	return c.Status(fiber.StatusOK).JSON(responseList)
}

// ListJobApplicationsForUser handles GET /api/jobs/user/:userId/applications
func (h *JobHandler) ListJobApplicationsForUser(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("userId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}
	applications, err := h.JobService.ListJobApplicationsByUserID(uint(userID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job applications"})
	}
	return c.Status(fiber.StatusOK).JSON(applications)
}

// Saved Job Handlers

// SaveJob handles POST /api/jobs/user/:userId/save/:jobId
func (h *JobHandler) SaveJob(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("userId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}
	jobID, err := strconv.ParseUint(c.Params("jobId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}

	if err := h.JobService.SaveJob(uint(userID), uint(jobID)); err != nil {
		// Check for the specific duplicate save error.
		if errors.Is(err, jobservice.ErrDuplicateSave) {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "Job already saved"}) // 409 Conflict
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to save job"})
	}

	return c.Status(http.StatusCreated).JSON(fiber.Map{"message": "Job saved successfully"})
}

// UnsaveJob handles DELETE /api/jobs/user/:userId/unsave/:jobId
func (h *JobHandler) UnsaveJob(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("userId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}
	jobID, err := strconv.ParseUint(c.Params("jobId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"}) // Corrected error message
	}

	if err := h.JobService.UnsaveJob(uint(userID), uint(jobID)); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job not saved for this user"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to unsave job"})
	}

	// Return a success message with 200 OK, instead of 204 No Content
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "Job unsaved successfully"})
}

// ListSavedJobs handles GET /api/jobs/user/:userId/saved
// jobhandler/jobhandler.go

func (h *JobHandler) ListSavedJobs(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("userId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}

	savedJobs, err := h.JobService.ListSavedJobs(uint(userID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve saved jobs"})
	}

	// Define the response structure.  This is VERY important for a clean API.
	type SavedJobResponse struct {
		SavedJobID     uint    `json:"saved_job_id"` // The ID of the SavedJob record itself
		JobID          uint    `json:"job_id"`       // The ID of the JobPost
		UserID         uint    `json:"user_id"`
		Title          string  `json:"title"` // Corrected field name: Title
		Description    string  `json:"description"`
		Location       string  `json:"location"`
		SalaryRange    string  `json:"salary_range"`
		JobPosition    string  `json:"job_position"`
		CompanyName    *string `json:"company_name"` // Pointer to handle NULL
		Status         bool    `json:"status"`
		Quantity       int     `json:"quantity"`
		ApplicantCount int64   `json:"applicant_count"`
	}

	responseList := make([]SavedJobResponse, 0, len(savedJobs))
	for _, savedJob := range savedJobs {
		// Check if JobPost and User are loaded before accessing.
		if savedJob.JobPost.ID == 0 {
			// Handle the case where JobPost is not loaded, e.g., skip, or return a partial response.
			fmt.Println("Warning: JobPost not preloaded correctly") // Log a warning
			responseList = append(responseList, SavedJobResponse{
				SavedJobID:  savedJob.ID,
				JobID:       savedJob.JobID,
				Title:       "Unknown Job - Please refresh", // Use the correct field name: Title
				CompanyName: nil,                            // Set to nil explicitly

			})
			continue // Skip to the next saved job
		}
		//Count applicant
		count, err := h.JobService.CountApplicationsByJobID(savedJob.JobPost.ID)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve applicant count"})
		}
		responseList = append(responseList, SavedJobResponse{
			SavedJobID:     savedJob.ID,    // The SavedJob's ID
			JobID:          savedJob.JobID, // The JobPost's ID
			UserID:         savedJob.UserID,
			Title:          savedJob.JobPost.Title, // Access the preloaded JobPost, Correct Field
			Description:    savedJob.JobPost.Description,
			Location:       savedJob.JobPost.Location,
			SalaryRange:    savedJob.JobPost.SalaryRange,
			JobPosition:    savedJob.JobPost.JobPosition,
			CompanyName:    savedJob.JobPost.User.CompanyName, // Access the preloaded User
			Status:         savedJob.JobPost.Status,
			Quantity:       savedJob.JobPost.Quantity,
			ApplicantCount: count,
		})
	}

	return c.Status(fiber.StatusOK).JSON(responseList)
}

// CheckIfJobIsSaved handles GET /api/jobs/user/:userId/saved/:jobId
func (h *JobHandler) CheckIfJobIsSaved(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("userId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}
	jobID, err := strconv.ParseUint(c.Params("jobId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID4"})
	}
	isSaved, err := h.JobService.IsJobSaved(uint(userID), uint(jobID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to check if job is saved"})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"is_saved": isSaved})
}

// ListJobApplications handles GET /api/jobs/applications with optional status filter.
func (h *JobHandler) ListJobApplications(c *fiber.Ctx) error {
	status := c.Query("status") // Get the "status" query parameter
	userIDStr := c.Query("user_id")
	jobIDStr := c.Query("job_id")

	var userID uint64
	var err error // Declare err *outside* the if blocks

	if userIDStr != "" {
		userID, err = strconv.ParseUint(userIDStr, 10, 64)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
		}
	}

	var jobID uint64
	if jobIDStr != "" {
		jobID, err = strconv.ParseUint(jobIDStr, 10, 64)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
		}
	}

	applications, err := h.JobService.ListJobApplicationsWithFilter(status, uint(userID), uint(jobID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job applications"})
	}

	return c.Status(fiber.StatusOK).JSON(applications)
}

// ListJobPostsByUserID handles GET /api/jobs/user/:userId, and now includes applicant count
func (h *JobHandler) ListJobPostsByUserID(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("userId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}

	jobPosts, err := h.JobService.ListJobPostsByUserID(uint(userID)) // Call the service
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job posts"})
	}

	// Create a response structure that includes the company name and applicant count.
	type Response struct {
		ID             uint    `json:"id"`
		Title          string  `json:"title"`
		Description    string  `json:"description"`
		Location       string  `json:"location"`
		SalaryRange    string  `json:"salary_range"`
		JobPosition    string  `json:"job_position"`
		CompanyName    *string `json:"company_name"` // Use a pointer to handle nil
		Status         bool    `json:"status"`       // Add the Status field
		Quantity       int     `json:"quantity"`
		ApplicantCount int64   `json:"applicant_count"` // Add applicant count
		UserID         uint    `json:"user_id"`
	}

	responseList := make([]Response, 0, len(jobPosts))
	for _, jobPost := range jobPosts {
		// Get the applicant count for EACH job post.
		count, err := h.JobService.CountApplicationsByJobID(jobPost.ID)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve applicant count"})
		}

		responseList = append(responseList, Response{
			ID:             jobPost.ID,
			Title:          jobPost.Title,
			Description:    jobPost.Description,
			Location:       jobPost.Location,
			SalaryRange:    jobPost.SalaryRange,
			JobPosition:    jobPost.JobPosition,
			CompanyName:    jobPost.User.CompanyName, // Direct Access
			Status:         jobPost.Status,
			Quantity:       jobPost.Quantity,
			ApplicantCount: count,
			UserID:         jobPost.UserID,
		})
	}
	return c.Status(fiber.StatusOK).JSON(responseList)
}
