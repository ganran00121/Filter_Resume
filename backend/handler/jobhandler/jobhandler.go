package jobhandler

import (
	"backend/pkg/model/jobmodel"
	"backend/pkg/service/jobservice"
	"bytes"
	"io"
	"net/http"
	"strconv"

	"github.com/gofiber/fiber/v2"
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
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}

	if err := h.JobService.DeleteJobPost(uint(id)); err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job Post not found"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to delete job post"})
	}

	return c.Status(fiber.StatusNoContent).Send(nil)
}

// ListJobPosts handles GET /api/jobs
func (h *JobHandler) ListJobPosts(c *fiber.Ctx) error {
	jobPosts, err := h.JobService.ListJobPosts()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job posts"})
	}
	return c.Status(fiber.StatusOK).JSON(jobPosts)
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

	var application jobmodel.JobApplication
	if err := c.BodyParser(&application); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	// Get the file from the request.
	file, err := c.FormFile("resume") // "resume" is the name of the form field
	if err != nil {
		if err == http.ErrMissingFile {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Resume file is required"})
		}
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Error retrieving file: " + err.Error()})
	}

	// Open the file.
	src, err := file.Open()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error opening file: " + err.Error()})
	}
	defer src.Close()

	// Read the file content into a byte slice.
	buf := bytes.NewBuffer(nil)
	if _, err := io.Copy(buf, src); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error reading file: " + err.Error()})
	}
	fileBytes := buf.Bytes()

	// Set the JobID from the URL parameter.  VERY IMPORTANT.
	application.JobID = uint(jobID)

	filePath, err := h.JobService.CreateJobApplication(&application, fileBytes)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create job application: " + err.Error()})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "Application submitted successfully", "file_path": filePath})
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
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID2"})
	}

	applications, err := h.JobService.ListJobApplicationsByJobID(uint(jobID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job applications"})
	}
	return c.Status(fiber.StatusOK).JSON(applications)
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
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID5"})
	}

	if err := h.JobService.SaveJob(uint(userID), uint(jobID)); err != nil {
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
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID3"})
	}

	if err := h.JobService.UnsaveJob(uint(userID), uint(jobID)); err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job not saved for this user"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to unsave job"})
	}

	return c.Status(fiber.StatusNoContent).Send(nil)
}

// ListSavedJobs handles GET /api/jobs/user/:userId/saved
func (h *JobHandler) ListSavedJobs(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("userId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}

	savedJobs, err := h.JobService.ListSavedJobs(uint(userID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve saved jobs"})
	}

	return c.Status(fiber.StatusOK).JSON(savedJobs)
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
	status := c.Query("status")
	userIDStr := c.Query("user_id")
	jobIDStr := c.Query("job_id")

	var userID uint64
	var err error

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
