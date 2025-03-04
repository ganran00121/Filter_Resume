package jobmodel

import (
	"backend/pkg/model/authmodel"
	"time"
)

type JobApplicationStatus string // Capitalize 'J', 'A', and 'S'

const (
	JobApplicationStatusPending  JobApplicationStatus = "pending"  // Capitalize 'J', 'A', 'S', and 'P'
	JobApplicationStatusAccepted JobApplicationStatus = "accepted" // Capitalize 'J', 'A', 'S', and 'A'
	JobApplicationStatusRejected JobApplicationStatus = "rejected" // Capitalize 'J', 'A', 'S', and 'R'
)

type SavedJob struct {
	ID        uint `gorm:"primaryKey"`
	UserID    uint `gorm:"not null"`
	JobID     uint `gorm:"not null"`
	CreatedAt time.Time
	UpdatedAt time.Time
	User      authmodel.User `gorm:"foreignKey:UserID"` //For preloading
	JobPost   JobPost        `gorm:"foreignKey:JobID"`  //For preloading
}

type JobPost struct {
	ID             uint           `gorm:"primaryKey"`
	UserID         uint           `gorm:"not null"`          // Foreign key referencing Users
	User           authmodel.User `gorm:"foreignKey:UserID"` // Add this line for the relationship
	Title          string         `gorm:"not null"`
	Description    string         `gorm:"type:text"` // Use 'text' for longer descriptions
	Location       string
	SalaryRange    string
	Quantity       int
	JobPosition    string
	Status         bool `gorm:"default:true"` // Use boolean; true for open, false for closed
	CreatedAt      time.Time
	UpdatedAt      time.Time
	ApplicantCount int              `gorm:"default:0"`        // Add this line
	Applications   []JobApplication `gorm:"foreignKey:JobID"` // Add this line to define the relationship
}

type JobApplication struct {
	ID            uint           `gorm:"primaryKey"`
	JobID         uint           `gorm:"not null"`
	UserID        uint           `gorm:"not null"`
	User          authmodel.User `gorm:"foreignKey:UserID"` // Add for relationship
	JobPost       JobPost        `gorm:"foreignKey:JobID"`  // Add for relationship
	ResumeFile    string
	Status        JobApplicationStatus `gorm:"type:varchar(20);default:'pending'"` // Use custom type
	CreatedAt     time.Time
	UpdatedAt     time.Time
	GeminiSummary string   `gorm:"type:text"`
	Score         *float64 `gorm:"type:double"`
}

type Message struct {
	ID          uint   `gorm:"primaryKey"`
	SenderID    uint   `gorm:"not null"` // Foreign key referencing Users
	ReceiverID  uint   `gorm:"not null"` // Foreign key referencing Users
	MessageText string `gorm:"type:longtext;not null"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}
