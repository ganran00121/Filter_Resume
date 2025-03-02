package jobservice

import (
	"backend/pkg/model/jobmodel"
	"backend/pkg/pdfextractor" // Import the pdfextractor package
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type IJobService interface {
	CreateJobPost(jobPost *jobmodel.JobPost) error
	GetJobPostByID(id uint) (*jobmodel.JobPost, error)
	UpdateJobPost(jobPost *jobmodel.JobPost) error
	DeleteJobPost(id uint) error
	ListJobPosts() ([]jobmodel.JobPost, error)
	ListJobPostsByCompanyID(companyID uint) ([]jobmodel.JobPost, error)
	ListOpenJobPosts() ([]jobmodel.JobPost, error)
	ListClosedJobPosts() ([]jobmodel.JobPost, error)

	CreateJobApplication(application *jobmodel.JobApplication, resumeFile []byte) (string, error)
	GetJobApplicationByID(id uint) (*jobmodel.JobApplication, error)
	UpdateJobApplication(application *jobmodel.JobApplication) error
	ListJobApplicationsByJobID(jobID uint) ([]jobmodel.JobApplication, error)
	ListJobApplicationsByUserID(userID uint) ([]jobmodel.JobApplication, error)

	SaveJob(userID, jobID uint) error
	UnsaveJob(userID, jobID uint) error
	ListSavedJobs(userID uint) ([]jobmodel.SavedJob, error)
	IsJobSaved(userID, jobID uint) (bool, error)
}

type JobService struct {
	DB           *gorm.DB
	PdfExtractor pdfextractor.IPdfExtractor
}

// NewJobService creates a new JobService.
func NewJobService(db *gorm.DB, pdfExtractor pdfextractor.IPdfExtractor) *JobService {
	return &JobService{DB: db, PdfExtractor: pdfExtractor}
}

// CreateJobApplication handles job application creation and resume upload.
func (s *JobService) CreateJobApplication(application *jobmodel.JobApplication, resumeFile []byte) (string, error) {
	// 1. Generate a unique file name.
	uniqueID := uuid.New().String()
	fileName := uniqueID + ".pdf"
	filePath := filepath.Join("uploads", "resumes", fileName) // Store in uploads/resumes

	// 2. Create the directory if it doesn't exist.
	err := os.MkdirAll(filepath.Dir(filePath), 0755) // 0755 permissions
	if err != nil {
		return "", fmt.Errorf("failed to create directory: %w", err)
	}

	// 3. Save the resume file.
	err = os.WriteFile(filePath, resumeFile, 0644) // 0644 permissions
	if err != nil {
		return "", fmt.Errorf("failed to save resume file: %w", err)
	}

	//4. Extract text from PDF
	extractedText, err := s.PdfExtractor.ExtractText(filePath)
	if err != nil {
		//Remove file if text extraction failed.
		os.Remove(filePath)
		return "", fmt.Errorf("failed to extract text from pdf: %w", err)
	}
	fmt.Println(extractedText) // Print the extracted text.  In a real application you will use the text.

	// 5. Set the file path in the application model.
	application.ResumeFile = filePath

	// 6. Save the application to the database.
	err = s.DB.Create(application).Error
	if err != nil {
		// Clean up the file if database save fails.  Important for consistency.
		os.Remove(filePath)
		return "", fmt.Errorf("failed to save application to database: %w", err)
	}

	return filePath, nil
}

// All Other Function in Job Service
func (s *JobService) GetJobPostByID(id uint) (*jobmodel.JobPost, error) {
	var jobPost jobmodel.JobPost
	err := s.DB.First(&jobPost, id).Error
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

func (s *JobService) ListJobPosts() ([]jobmodel.JobPost, error) {
	var jobPosts []jobmodel.JobPost
	err := s.DB.Find(&jobPosts).Error
	return jobPosts, err
}

// ListJobPostsByCompanyID now filters by UserID (due to model change)
func (s *JobService) ListJobPostsByCompanyID(userID uint) ([]jobmodel.JobPost, error) {
	var jobPosts []jobmodel.JobPost
	err := s.DB.Where("user_id = ?", userID).Find(&jobPosts).Error // Corrected to UserID
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

func (s *JobService) CreateJobPost(jobPost *jobmodel.JobPost) error {
	return s.DB.Create(jobPost).Error
}
