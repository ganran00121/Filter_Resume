package authmodel

import (
	"time"
)

type User struct {
	ID        uint   `gorm:"primaryKey"`
	Name      string `gorm:"not null"`
	Email     string `gorm:"unique;not null"`
	Password  string `gorm:"not null"`
	Phone     string `gorm:"not null"`
	UserType  string `gorm:"type:enum('applicant', 'company');not null"`
	CreatedAt time.Time
	UpdatedAt time.Time
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required"`
	Name     string `json:"name" binding:"required"`
	Password string `json:"password" binding:"required"`
	Phone    string `json:"phone" binding:"required"`
	UserType string `json:"user_type" binding:"required,oneof=applicant company"`
}

type CompanyProfile struct {
	ID          uint   `gorm:"primaryKey"`
	UserID      uint   `gorm:"not null;uniqueIndex"`
	CompanyName string `gorm:"not null"`
	Description string
	Logo        string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type SavedJob struct {
	ID        uint `gorm:"primaryKey"`
	UserID    uint `gorm:"not null"`
	JobID     uint `gorm:"not null"`
	CreatedAt time.Time
	UpdatedAt time.Time
}

type JobPost struct {
	ID          uint   `gorm:"primaryKey"`
	CompanyID   uint   `gorm:"not null"`
	Title       string `gorm:"not null"`
	Description string
	Location    string
	SalaryRange string
	Quantity    int
	JobPosition string
	Status      string `gorm:"type:enum('open', 'closed');default:'open'"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type JobApplication struct {
	ID         uint `gorm:"primaryKey"`
	JobID      uint `gorm:"not null"`
	UserID     uint `gorm:"not null"`
	ResumeFile string
	Status     string `gorm:"type:enum('pending', 'accepted', 'rejected');not null"`
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type Message struct {
	ID          uint   `gorm:"primaryKey"`
	SenderID    uint   `gorm:"not null"`
	ReceiverID  uint   `gorm:"not null"`
	MessageText string `gorm:"not null"`
	CreatedAt   time.Time
}

type Notification struct {
	ID         uint   `gorm:"primaryKey"`
	UserID     uint   `gorm:"not null"`
	Message    string `gorm:"not null"`
	ReadStatus bool   `gorm:"default:false"`
	CreatedAt  time.Time
}

type FirebaseResponse struct {
	IDToken string `json:"idToken"`
}
