package authmodel

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID           uint    `gorm:"primaryKey"`
	Name         string  `gorm:"not null"`
	Email        string  `gorm:"unique;not null"`
	Password     string  `gorm:"not null"`
	Phone        string  `gorm:"not null"`
	UserType     string  `gorm:"type:enum('applicant', 'company');not null"`
	CompanyName  *string `gorm:"type:varchar(255);default:NULL"`
	ProfileImage *string `gorm:"type:varchar(255);default:NULL"`
	CreatedAt    time.Time
	UpdatedAt    time.Time
}
type LoginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type ResetPasswordRequest struct {
	Email       string `json:"email" binding:"required,email"`
	NewPassword string `json:"new_password" binding:"required"`
}
type UpdateProfileRequest struct {
	Name  *string `json:"name"`  // Use pointers to allow partial updates
	Phone *string `json:"phone"` // Use pointers to allow partial updates
}
type RegisterRequest struct {
	Email       string  `json:"email" binding:"required"`
	Name        string  `json:"name" binding:"required"`
	Password    string  `json:"password" binding:"required"`
	Phone       string  `json:"phone" binding:"required"`
	UserType    string  `json:"user_type" binding:"required,oneof=applicant company"`
	CompanyName *string `json:"company_name"`
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

type Message struct {
	ID          uint   `gorm:"primaryKey"`
	SenderID    uint   `gorm:"not null"` // Foreign key referencing Users
	ReceiverID  uint   `gorm:"not null"` // Foreign key referencing Users
	MessageText string `gorm:"type:text;not null"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
	DeletedAt   gorm.DeletedAt `gorm:"index"`
	Sender      User           `gorm:"foreignKey:SenderID"`   // For preloading
	Receiver    User           `gorm:"foreignKey:ReceiverID"` // For preloading
}
type Notification struct { //Move form jobmodel to authmodel
	ID        uint   `gorm:"primaryKey"`
	UserID    uint   `gorm:"not null"`
	Message   string `gorm:"not null"`
	IsRead    bool   `gorm:"default:false"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`
	User      User           `gorm:"foreignKey:UserID"`
}

type FirebaseResponse struct {
	IDToken string `json:"idToken"`
}
