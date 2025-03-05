package jobservice

import (
	"backend/pkg/model/jobmodel"
	"backend/pkg/pdfextractor"
	"backend/pkg/service/geminiservice"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// IJobService interface
type IJobService interface {
	CreateJobPost(jobPost *jobmodel.JobPost) error
	GetJobPostByID(id uint) (*jobmodel.JobPost, error)
	UpdateJobPost(jobPost *jobmodel.JobPost) error
	DeleteJobPost(jobID, userID uint) error
	ListJobPosts() ([]jobmodel.JobPost, error) // Modified return type
	ListJobPostsByCompanyID(companyID uint) ([]jobmodel.JobPost, error)
	ListOpenJobPosts() ([]jobmodel.JobPost, error)
	ListClosedJobPosts() ([]jobmodel.JobPost, error)
	CreateJobApplication(application *jobmodel.JobApplication, resumeFile []byte) (string, error)
	GetJobApplicationByID(id uint) (*jobmodel.JobApplication, error)
	UpdateJobApplication(application *jobmodel.JobApplication) error
	ListJobApplicationsByJobID(jobID uint) ([]jobmodel.JobApplication, error)
	ListJobApplicationsByUserID(userID uint) ([]jobmodel.JobApplication, error)
	ListJobApplicationsWithFilter(status string, userID, jobID uint) ([]jobmodel.JobApplication, error) // CRITICAL: New method
	SaveJob(userID, jobID uint) error
	UnsaveJob(userID, jobID uint) error
	ListSavedJobs(userID uint) ([]jobmodel.SavedJob, error)
	IsJobSaved(userID, jobID uint) (bool, error)
	GetAllApplicants() ([]jobmodel.JobApplication, error)
	ListJobPostsByUserID(userID uint) ([]jobmodel.JobPost, error)
	CountApplicationsByJobID(jobID uint) (int64, error)
}

type JobService struct {
	DB            *gorm.DB
	PdfExtractor  pdfextractor.IPdfExtractor
	GeminiService geminiservice.IGeminiService // Inject Gemini Service
}

// NewJobService creates a new JobService, injecting dependencies.
func NewJobService(db *gorm.DB, pdfExtractor pdfextractor.IPdfExtractor, geminiService geminiservice.IGeminiService) *JobService {
	return &JobService{DB: db, PdfExtractor: pdfExtractor, GeminiService: geminiService}
}

var ErrDuplicateSave = errors.New("job already saved by this user")
var ErrUnauthorized = errors.New("unauthorized")

const (
	errInvalidJobID    = "Invalid job ID"
	errJobPostNotFound = "Job post not found"
	errUnauthorized    = "Unauthorized"
	errDeleteJobPost   = "Failed to delete job post"
)

func (s *JobService) CreateJobPost(jobPost *jobmodel.JobPost) error {
	return s.DB.Create(jobPost).Error
}

func (s *JobService) GetJobPostByID(id uint) (*jobmodel.JobPost, error) {
	var jobPost jobmodel.JobPost
	err := s.DB.Preload("User").First(&jobPost, id).Error //  <---  CRITICAL CHANGE: Preload("User")
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil // Return nil, nil if not found
	}
	return &jobPost, err
}

func (s *JobService) UpdateJobPost(jobPost *jobmodel.JobPost) error {
	result := s.DB.Model(jobPost).Updates(jobPost)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound // Or a custom error indicating no update happened
	}
	return nil
}

func (s *JobService) DeleteJobPost(jobID, userID uint) error {
	// 1. Retrieve the job post to check the owner.
	var jobPost jobmodel.JobPost
	result := s.DB.First(&jobPost, jobID)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return gorm.ErrRecordNotFound // Job post not found
		}
		return fmt.Errorf("failed to retrieve job post: %w", result.Error)
	}

	// 2. Check if the user is the owner of the job post.
	if jobPost.UserID != userID {
		return ErrUnauthorized // Unauthorized access
	}

	// 3. Delete the job post.
	result = s.DB.Delete(&jobmodel.JobPost{}, jobID)
	if result.Error != nil {
		return fmt.Errorf("failed to delete job post: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		// This case should not happen after retrieve job post.
		// Because the jobPost already retrieves in the step before.
		return gorm.ErrRecordNotFound // Should not happen, but good to check
	}

	return nil
}

// ListJobPosts retrieves all job posts, preloading the associated User.
func (s *JobService) ListJobPosts() ([]jobmodel.JobPost, error) {
	var jobPosts []jobmodel.JobPost
	err := s.DB.Preload("User").Find(&jobPosts).Error // Preload the User
	return jobPosts, err
}

// ListJobPostsByCompanyID now filters by UserID (due to model change) and preloads User.
func (s *JobService) ListJobPostsByCompanyID(companyID uint) ([]jobmodel.JobPost, error) {
	var jobPosts []jobmodel.JobPost
	// VERY IMPORTANT: Exclude soft-deleted records.
	err := s.DB.Preload("User").Where("user_id = ? AND deleted_at IS NULL", companyID).Find(&jobPosts).Error // Preload User
	return jobPosts, err
}

// Added: List only open job posts
func (s *JobService) ListOpenJobPosts() ([]jobmodel.JobPost, error) {
	var jobPosts []jobmodel.JobPost
	err := s.DB.Where("status = ?", true).Find(&jobPosts).Error // true for open
	return jobPosts, err
}

// Added: List only closed job posts
func (s *JobService) ListClosedJobPosts() ([]jobmodel.JobPost, error) {
	var jobPosts []jobmodel.JobPost
	err := s.DB.Where("status = ?", false).Find(&jobPosts).Error // false for closed
	return jobPosts, err
}

// CreateJobApplication handles job application creation and resume upload.
func (s *JobService) CreateJobApplication(application *jobmodel.JobApplication, resumeFile []byte) (string, error) {
	uniqueID := uuid.New().String()
	fileName := uniqueID + ".pdf"
	filePath := filepath.Join("uploads", "resumes", fileName)

	// 1. Create directory.
	err := os.MkdirAll(filepath.Dir(filePath), 0755)
	if err != nil {
		return "", fmt.Errorf("failed to create directory: %w", err)
	}

	// 2. Save resume file.
	err = os.WriteFile(filePath, resumeFile, 0644)
	if err != nil {
		return "", fmt.Errorf("failed to save resume file: %w", err)
	}

	// 3. Extract text from PDF.
	extractedText, err := s.PdfExtractor.ExtractText(filePath)
	if err != nil {
		os.Remove(filePath) // Clean up if extraction fails.
		return "", fmt.Errorf("failed to extract text from PDF: %w", err)
	}

	// 4. Set file path.
	application.ResumeFile = filePath

	// --- Transaction Start ---
	tx := s.DB.Begin()
	if tx.Error != nil {
		os.Remove(filePath) // Clean up on transaction start failure
		return "", fmt.Errorf("failed to begin database transaction: %w", tx.Error)
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
			os.Remove(filePath) // Clean up on panic
		}
	}()

	// 5. Save the initial application (before Gemini processing).
	err = tx.Create(application).Error
	if err != nil {
		tx.Rollback()
		os.Remove(filePath) // Clean up on database error
		return "", fmt.Errorf("failed to save application: %w", err)
	}

	// 6. Get the JobPost (needed for the Gemini prompt).
	jobPost, err := s.GetJobPostByID(application.JobID) // Use GetJobPostByID (soft-delete aware)
	if err != nil {
		tx.Rollback()
		os.Remove(filePath)
		return "", fmt.Errorf("failed to get job post: %w", err)
	}
	if jobPost == nil { // Handle case where GetJobPostByID returns nil, nil
		tx.Rollback()
		os.Remove(filePath)
		return "", fmt.Errorf("job post with id %d not found", application.JobID)
	}

	// 7. Call Gemini (with job description and resume text).
	summary, score, questions, err := s.GeminiService.GenerateContent(jobPost.Description, extractedText)
	if err != nil {
		// Log and continue.  Don't prevent application submission on Gemini failure.
		fmt.Printf("Gemini API call failed: %v\n", err)
		summary = "Resume analysis with Gemini failed." // Set a default summary
		// We do NOT rollback here.  We still want the application to be saved.
	}

	// 8. Store Gemini results in the JobApplication.
	application.GeminiSummary = summary // Always store the summary
	if score != nil {
		application.Score = score // Store score (if available)
	}
	if questions != nil {
		application.Questions = questions
	}

	fmt.Println(application)

	if err := tx.Save(application).Error; err != nil {
		tx.Rollback() // Rollback if saving to job application fails
		os.Remove(filePath)
		return "", fmt.Errorf("failed to save Gemini data: %w", err)
	}
	// 9. Create a Message with the QUESTIONS (if any).
	if questions != nil && *questions != "" { // Check if questions are present
		message := jobmodel.Message{
			SenderID:    jobPost.UserID,     // Use the system user ID.
			ReceiverID:  application.UserID, // Send to the applicant.
			MessageText: *questions,         // Use the *questions* from Gemini.
		}
		if err := tx.Create(&message).Error; err != nil {
			tx.Rollback() // Rollback if message creation fails
			os.Remove(filePath)
			return "", fmt.Errorf("failed to create message: %w", err)
		}
	}

	// --- Transaction Commit ---
	if err := tx.Commit().Error; err != nil {
		tx.Rollback()       // Rollback for any commit error
		os.Remove(filePath) // Clean up
		return "", fmt.Errorf("failed to commit transaction: %w", err)
	}

	return filePath, nil
}

func (s *JobService) GetJobApplicationByID(id uint) (*jobmodel.JobApplication, error) {
	var application jobmodel.JobApplication
	err := s.DB.
		Preload("User").              // Preload the User (applicant)
		Preload("JobPost").           // Preload the JobPost
		Preload("JobPost.User").      // Preload the User of Job Post
		First(&application, id).Error // Find the application by ID

	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil // Return nil, nil for not found
	} else if err != nil {
		return nil, fmt.Errorf("failed to retrieve job application: %w", err)
	}
	return &application, nil
}

func (s *JobService) UpdateJobApplication(application *jobmodel.JobApplication) error {
	result := s.DB.Model(application).Updates(application)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s *JobService) ListJobApplicationsByJobID(jobID uint) ([]jobmodel.JobApplication, error) {
	var applications []jobmodel.JobApplication
	err := s.DB.
		Preload("User").                                   //  <-- CRITICAL: Preload the User (applicant)
		Preload("JobPost").                                //  <-- Preload JobPost
		Where("job_id = ? AND deleted_at IS NULL", jobID). // Filter by job_id and exclude soft-deleted
		Find(&applications).Error
	return applications, err
}

func (s *JobService) ListJobApplicationsByUserID(userID uint) ([]jobmodel.JobApplication, error) {
	var applications []jobmodel.JobApplication
	err := s.DB.Where("user_id = ?", userID).Find(&applications).Error
	return applications, err
}

// SavedJob methods
func (s *JobService) SaveJob(userID, jobID uint) error {
	// 1. Check if the job is ALREADY saved by the user.
	var existingSavedJob jobmodel.SavedJob
	result := s.DB.Where("user_id = ? AND job_id = ?", userID, jobID).First(&existingSavedJob)

	if result.Error == nil {
		// A record was found, meaning it's a duplicate.
		return ErrDuplicateSave
	} else if !errors.Is(result.Error, gorm.ErrRecordNotFound) {
		// Some other database error occurred.
		return fmt.Errorf("failed to check for existing saved job: %w", result.Error)
	}

	// 2. If no existing record, proceed with saving.
	savedJob := jobmodel.SavedJob{UserID: userID, JobID: jobID}
	if err := s.DB.Create(&savedJob).Error; err != nil {
		return fmt.Errorf("failed to save job: %w", err)
	}

	return nil
}

func (s *JobService) UnsaveJob(userID, jobID uint) error {
	result := s.DB.Where("user_id = ? AND job_id = ?", userID, jobID).Delete(&jobmodel.SavedJob{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound // Important: return error if nothing was deleted
	}
	return nil
}

func (s *JobService) ListSavedJobs(userID uint) ([]jobmodel.SavedJob, error) {
	var savedJobs []jobmodel.SavedJob
	err := s.DB.
		Preload("JobPost").
		Preload("JobPost.User").
		Where("user_id = ?", userID).
		Find(&savedJobs).Error
	return savedJobs, err
}

func (s *JobService) IsJobSaved(userID, jobID uint) (bool, error) {
	var count int64
	err := s.DB.Model(&jobmodel.SavedJob{}).Where("user_id = ? AND job_id = ?", userID, jobID).Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (s *JobService) GetAllApplicants() ([]jobmodel.JobApplication, error) {
	var applications []jobmodel.JobApplication
	err := s.DB.Find(&applications).Error // Find *ALL* applications
	return applications, err
}

// ListJobApplicationsWithFilter retrieves job applications with optional filters.
func (s *JobService) ListJobApplicationsWithFilter(status string, userID, jobID uint) ([]jobmodel.JobApplication, error) {
	var applications []jobmodel.JobApplication
	query := s.DB.Model(&jobmodel.JobApplication{})

	if status != "" {
		switch status {
		case string(jobmodel.JobApplicationStatusPending):
			query = query.Where("status = ?", jobmodel.JobApplicationStatusPending)
		case string(jobmodel.JobApplicationStatusAccepted):
			query = query.Where("status = ?", jobmodel.JobApplicationStatusAccepted)
		case string(jobmodel.JobApplicationStatusRejected):
			query = query.Where("status = ?", jobmodel.JobApplicationStatusRejected)
		default:
			// Handle invalid status values (optional)
			return nil, fmt.Errorf("invalid status filter: %s", status)

		}
	}
	if userID != 0 {
		query = query.Where("user_id = ?", userID)
	}
	if jobID != 0 {
		query = query.Where("job_id = ?", jobID)
	}

	err := query.Find(&applications).Error
	return applications, err
}

func (s *JobService) ListJobPostsByUserID(userID uint) ([]jobmodel.JobPost, error) {
	var jobPosts []jobmodel.JobPost
	err := s.DB.Preload("User").
		Where("user_id = ? AND deleted_at IS NULL", userID). // Exclude soft-deleted job posts
		Find(&jobPosts).Error
	return jobPosts, err
}

// CountApplicationsByJobID counts applications for a specific job.
func (s *JobService) CountApplicationsByJobID(jobID uint) (int64, error) {
	var count int64
	err := s.DB.Model(&jobmodel.JobApplication{}).Where("job_id = ?", jobID).Count(&count).Error
	return count, err
}
