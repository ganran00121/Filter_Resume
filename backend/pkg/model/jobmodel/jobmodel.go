package jobmodel

import "time"

type SavedJob struct {
	ID        uint `gorm:"primaryKey"`
	UserID    uint `gorm:"not null"`
	JobID     uint `gorm:"not null"`
	CreatedAt time.Time
	UpdatedAt time.Time
}

type JobPost struct {
	ID          uint   `gorm:"primaryKey"`
	UserID      uint   `gorm:"not null"`
	Title       string `gorm:"not null"`
	Description string
	Location    string
	SalaryRange string
	Quantity    int
	JobPosition string
	Status      bool `gorm:"default:true"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type JobApplication struct {
	ID            uint `gorm:"primaryKey"`
	JobID         uint `gorm:"not null"`
	UserID        uint `gorm:"not null"`
	ResumeFile    string
	Status        string `gorm:"type:enum('pending', 'accepted', 'rejected');default:'pending'"`
	GeminiSummary string `gorm:"type:longtext"`
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type Message struct {
	ID          uint   `gorm:"primaryKey"`
	SenderID    uint   `gorm:"not null"` // Foreign key referencing Users
	ReceiverID  uint   `gorm:"not null"` // Foreign key referencing Users
	MessageText string `gorm:"type:longtext;not null"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type JobApplicationStatus string // Capitalize 'J', 'A', and 'S'

const (
	JobApplicationStatusPending  JobApplicationStatus = "pending"  // Capitalize 'J', 'A', 'S', and 'P'
	JobApplicationStatusAccepted JobApplicationStatus = "accepted" // Capitalize 'J', 'A', 'S', and 'A'
	JobApplicationStatusRejected JobApplicationStatus = "rejected" // Capitalize 'J', 'A', 'S', and 'R'
)
