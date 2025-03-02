package jobhandler

import (
	"backend/pkg/model/jobmodel"
	"backend/pkg/service/jobservice"
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
	ListJobPostsByCompany(c *fiber.Ctx) error // Keep, but now filters by UserID
	ListOpenJobPosts(c *fiber.Ctx) error      // Added: List only open jobs
	ListClosedJobPosts(c *fiber.Ctx) error    // Added: List only closed jobs
	CreateJobApplication(c *fiber.Ctx) error
	GetJobApplication(c *fiber.Ctx) error
	UpdateJobApplication(c *fiber.Ctx) error
	ListJobApplicationsForJob(c *fiber.Ctx) error
	ListJobApplicationsForUser(c *fiber.Ctx) error

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

func (h *JobHandler) CreateJobPost(c *fiber.Ctx) error {
	var jobPost jobmodel.JobPost
	if err := c.BodyParser(&jobPost); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	//  jobPost.Status is now a boolean.  It defaults to true (open)
	//  if not provided in the request body.  You *could* add validation
	//  here to explicitly check if the user is allowed to set a specific status,
	//  but by default, new job posts will be open.

	if err := h.JobService.CreateJobPost(&jobPost); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create job post"})
	}

	return c.Status(fiber.StatusCreated).JSON(jobPost)
}

func (h *JobHandler) GetJobPost(c *fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
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

func (h *JobHandler) UpdateJobPost(c *fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}

	var jobPost jobmodel.JobPost
	if err := c.BodyParser(&jobPost); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	// Set the ID from the path parameter, ensuring consistency
	jobPost.ID = uint(id)

	if err := h.JobService.UpdateJobPost(&jobPost); err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job post not found"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update job post"})
	}

	return c.Status(fiber.StatusOK).JSON(jobPost)
}

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

func (h *JobHandler) ListJobPosts(c *fiber.Ctx) error {
	jobPosts, err := h.JobService.ListJobPosts()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job posts"})
	}
	return c.Status(fiber.StatusOK).JSON(jobPosts)
}

// ListJobPostsByCompany now filters by UserID
func (h *JobHandler) ListJobPostsByCompany(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("companyId"), 10, 64) // Keep parameter name, but it's UserID
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"}) // Corrected error message
	}

	jobPosts, err := h.JobService.ListJobPostsByCompanyID(uint(userID)) // Now passes UserID
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job posts"})
	}
	return c.Status(fiber.StatusOK).JSON(jobPosts)
}

// Added: List only open jobs
func (h *JobHandler) ListOpenJobPosts(c *fiber.Ctx) error {
	jobPosts, err := h.JobService.ListOpenJobPosts()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve open job posts"})
	}
	return c.Status(fiber.StatusOK).JSON(jobPosts)
}

// Added: List only closed jobs
func (h *JobHandler) ListClosedJobPosts(c *fiber.Ctx) error {
	jobPosts, err := h.JobService.ListClosedJobPosts()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve closed job posts"})
	}
	return c.Status(fiber.StatusOK).JSON(jobPosts)
}

// Job Application Handlers

func (h *JobHandler) CreateJobApplication(c *fiber.Ctx) error {
	var application jobmodel.JobApplication
	if err := c.BodyParser(&application); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	//  application.Status defaults to "pending" due to the model definition.
	//  You *could* add validation here to make sure the user isn't trying to
	//  set a status they shouldn't (e.g., an applicant setting "accepted").

	if err := h.JobService.CreateJobApplication(&application); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create job application"})
	}

	return c.Status(fiber.StatusCreated).JSON(application)
}

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

	//  Here's where you might add authorization checks.  For example, you
	//  might only allow an admin or the company that posted the job to
	//  update the application status.  A regular applicant should *not* be
	//  able to update the status directly.

	if err := h.JobService.UpdateJobApplication(&application); err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job application not found"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update job application"})
	}

	return c.Status(fiber.StatusOK).JSON(application)
}

func (h *JobHandler) ListJobApplicationsForJob(c *fiber.Ctx) error {
	jobID, err := strconv.ParseUint(c.Params("jobId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}

	applications, err := h.JobService.ListJobApplicationsByJobID(uint(jobID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve job applications"})
	}
	return c.Status(fiber.StatusOK).JSON(applications)
}

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
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to save job"})
	}

	return c.Status(http.StatusCreated).JSON(fiber.Map{"message": "Job saved successfully"})
}

func (h *JobHandler) UnsaveJob(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("userId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}
	jobID, err := strconv.ParseUint(c.Params("jobId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}

	if err := h.JobService.UnsaveJob(uint(userID), uint(jobID)); err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Job not saved for this user"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to unsave job"})
	}

	return c.Status(fiber.StatusNoContent).Send(nil)
}

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

func (h *JobHandler) CheckIfJobIsSaved(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("userId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}
	jobID, err := strconv.ParseUint(c.Params("jobId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}
	isSaved, err := h.JobService.IsJobSaved(uint(userID), uint(jobID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to check if job is saved"})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"is_saved": isSaved})
}
