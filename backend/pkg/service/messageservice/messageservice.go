package messageservice

import (
	"backend/pkg/model/authmodel" // Assuming Message is in authmodel
	"errors"
	"fmt"

	"gorm.io/gorm"
)

type IMessageService interface {
	SendMessage(senderID, receiverID uint, messageText string) (*authmodel.Message, error)
	GetMessagesForUser(userID uint, loggedInUserID uint, loggedInUserType string) ([]authmodel.Message, error) // Modified signature
	GetMessageByID(messageID uint) (*authmodel.Message, error)                                                 // Might be useful
	// ... other methods (e.g., MarkAsRead, DeleteMessage, SearchMessages) ...
}

type MessageService struct {
	DB *gorm.DB
}

func NewMessageService(db *gorm.DB) *MessageService {
	return &MessageService{DB: db}
}

func (s *MessageService) SendMessage(senderID, receiverID uint, messageText string) (*authmodel.Message, error) {
	message := authmodel.Message{
		SenderID:    senderID,
		ReceiverID:  receiverID,
		MessageText: messageText,
	}

	result := s.DB.Create(&message)
	if result.Error != nil {
		return nil, fmt.Errorf("failed to create message: %w", result.Error)
	}

	return &message, nil
}

func (s *MessageService) GetMessagesForUser(userID uint, loggedInUserID uint, loggedInUserType string) ([]authmodel.Message, error) {
	var messages []authmodel.Message

	query := s.DB.Preload("Sender").Preload("Receiver").Order("created_at DESC")

	if loggedInUserType == "applicant" {
		// Applicants can see all messages sent to or from them.
		query = query.Where("sender_id = ? OR receiver_id = ?", userID, userID)
	} else if loggedInUserType == "company" {
		// Companies can only see messages related to their job postings.
		query = query.Joins("JOIN job_applications ON messages.receiver_id = job_applications.user_id").
			Joins("JOIN job_posts ON job_applications.job_id = job_posts.id").
			Where("job_posts.user_id = ? AND (messages.sender_id = ? OR messages.receiver_id = ?)", loggedInUserID, userID, userID)

	} else {
		// Handle other user types (or return an error)
		return nil, fmt.Errorf("unauthorized user type: %s", loggedInUserType)
	}

	err := query.Find(&messages).Error
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve messages: %w", err)
	}

	return messages, nil
}
func (s *MessageService) GetMessageByID(messageID uint) (*authmodel.Message, error) {
	var message authmodel.Message
	result := s.DB.Preload("Sender").Preload("Receiver").First(&message, messageID) //Preload sender and receiver
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to retrieve message: %w", result.Error)
	}
	return &message, nil
}
