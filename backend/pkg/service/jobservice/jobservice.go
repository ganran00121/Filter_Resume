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
	DeleteJobPost(id uint) error
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

func (s *JobService) DeleteJobPost(id uint) error {
	result := s.DB.Delete(&jobmodel.JobPost{}, id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
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
func (s *JobService) ListJobPostsByCompanyID(userID uint) ([]jobmodel.JobPost, error) {
	var jobPosts []jobmodel.JobPost
	err := s.DB.Preload("User").Where("user_id = ?", userID).Find(&jobPosts).Error // Preload and filter by UserID
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
	// 1. Generate unique file name.
	uniqueID := uuid.New().String()
	fileName := uniqueID + ".pdf"
	filePath := filepath.Join("uploads", "resumes", fileName)

	// 2. Create directory.
	err := os.MkdirAll(filepath.Dir(filePath), 0755)
	if err != nil {
		return "", fmt.Errorf("failed to create directory: %w", err)
	}

	// 3. Save resume file.
	err = os.WriteFile(filePath, resumeFile, 0644)
	if err != nil {
		return "", fmt.Errorf("failed to save resume file: %w", err)
	}

	// 4. Extract text from PDF.
	extractedText, err := s.PdfExtractor.ExtractText(filePath)
	if err != nil {
		os.Remove(filePath) // Clean up on extraction failure.
		return "", fmt.Errorf("failed to extract text from PDF: %w", err)
	}

	// 5. Set file path.
	application.ResumeFile = filePath

	// --- Transaction Start ---
	tx := s.DB.Begin()
	if tx.Error != nil {
		os.Remove(filePath)
		return "", fmt.Errorf("failed to begin database transaction: %w", tx.Error)
	}
	// Use defer for rollback in case of panic
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 6. Save application.
	err = tx.Create(application).Error // Use tx, not s.DB
	if err != nil {
		tx.Rollback()       // Rollback on application creation failure
		os.Remove(filePath) // Clean up.
		return "", fmt.Errorf("failed to save application: %w", err)

	}

	// 7. Process with Gemini.
	generatedText, err := s.GeminiService.GenerateContent(extractedText)
	if err != nil {
		//Don't rollback here. Log the error, and continue without Gemini
		fmt.Printf("Gemini API call failed: %v\n", err)

	} else {
		// 8.  Store response in JobApplication
		// *Important*: We're updating the *existing* application object
		// that's already in the database (within the transaction).
		application.GeminiSummary = generatedText
		if err := tx.Save(application).Error; err != nil { // Use tx.Save, not tx.Create
			tx.Rollback() // Rollback if saving the summary fails
			os.Remove(filePath)
			return "", fmt.Errorf("failed to save Gemini summary: %w", err)
		}

	}

	// --- Transaction Commit ---
	if err := tx.Commit().Error; err != nil {
		os.Remove(filePath) //Clean up file
		return "", fmt.Errorf("failed to commit transaction: %w", err)
	}

	return filePath, nil
}

func (s *JobService) GetJobApplicationByID(id uint) (*jobmodel.JobApplication, error) {
	var application jobmodel.JobApplication
	err := s.DB.First(&application, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &application, err
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
	err := s.DB.Where("job_id = ?", jobID).Find(&applications).Error
	return applications, err
}

func (s *JobService) ListJobApplicationsByUserID(userID uint) ([]jobmodel.JobApplication, error) {
	var applications []jobmodel.JobApplication
	err := s.DB.Where("user_id = ?", userID).Find(&applications).Error
	return applications, err
}

// SavedJob methods
func (s *JobService) SaveJob(userID, jobID uint) error {
	savedJob := jobmodel.SavedJob{UserID: userID, JobID: jobID}
	return s.DB.Create(&savedJob).Error
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
	err := s.DB.Where("user_id = ?", userID).Find(&savedJobs).Error
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
