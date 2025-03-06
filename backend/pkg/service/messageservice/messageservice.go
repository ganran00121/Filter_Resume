package messageservice

import (
	"backend/pkg/model/authmodel" // Assuming Message is in authmodel
	"backend/pkg/model/jobmodel"
	"backend/pkg/pdfextractor"
	"backend/pkg/service/geminiservice"
	"backend/pkg/service/jobservice"
	"errors"
	"fmt"

	"gorm.io/gorm"
)

type IMessageService interface {
	SendMessage(senderID, receiverID uint, messageText string) (*authmodel.Message, error)
	ProcessAndSendMessage(senderID, receiverID uint, messageText string, jobID uint) (string, error)
	GetMessagesForUser(userID uint, loggedInUserID uint, loggedInUserType string) ([]authmodel.Message, error) // Modified signature
	GetMessageByID(messageID uint) (*authmodel.Message, error)                                                 // Might be useful
	GetUserMessagesWithGemini(userID uint, jobID uint) ([]authmodel.Message, error)
	InteractWithGemini(senderID, receiverID uint, messageText string, JobID uint) (*authmodel.Message, *authmodel.Message, error)
	// ... other methods (e.g., MarkAsRead, DeleteMessage, SearchMessages) ...
}

type MessageService struct {
	DB            *gorm.DB
	GeminiService geminiservice.IGeminiService // Inject Gemini Service
	JobService    jobservice.IJobService
	PdfExtractor  pdfextractor.IPdfExtractor
}

func NewMessageService(db *gorm.DB, geminiService geminiservice.IGeminiService, jobService jobservice.IJobService, pdfExtractor pdfextractor.IPdfExtractor) *MessageService {
	return &MessageService{DB: db, GeminiService: geminiService, JobService: jobService, PdfExtractor: pdfExtractor}
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

// ProcessAndSendMessage calls Gemini and then saves the message.
func (s *MessageService) ProcessAndSendMessage(senderID, receiverID uint, messageText string, jobID uint) (string, error) {
	// 1. Get the previous conversation history.
	previousMessages, err := s.GetUserMessagesWithGemini(senderID, jobID) // Corrected call

	if err != nil {
		//  Log error, but don't necessarily prevent sending *this* message.
		fmt.Printf("Error retrieving previous messages: %v\n", err)
		previousMessages = []authmodel.Message{} // Use an empty slice if no history.
	}

	// 2. Build the conversation history string.
	conversationHistory := ""
	for _, msg := range previousMessages {
		// Determine who sent the message and format accordingly.
		if msg.SenderID == senderID {
			conversationHistory += fmt.Sprintf("Company: %s\n", msg.MessageText)
		} else {
			conversationHistory += fmt.Sprintf("Applicant: %s\n", msg.MessageText)
		}
	}
	// 3. Get Applicant Resume text
	var application jobmodel.JobApplication
	if err := s.DB.
		Preload("User").                                                               // Preload User and JobPost
		Preload("JobPost.User").                                                       //Preload the company user
		Where("job_id = ? AND user_id = ? AND deleted_at IS NULL", jobID, receiverID). // receiverID is applicant id
		First(&application).Error; err != nil {

		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", fmt.Errorf("no applications found for this job")
		}
		return "", fmt.Errorf("failed to retrieve application")
	}
	//Get resume text by extract from file
	extractedText, err := s.PdfExtractor.ExtractText(application.ResumeFile)
	if err != nil {
		return "", fmt.Errorf("failed to extract from PDF")
	}

	// 4. Call Gemini with the conversation history + new message.
	responseText, _, _, err := s.GeminiService.GenerateContentWithHistory(application.JobPost.Description, extractedText, conversationHistory+"\nCompany: "+messageText, *application.Questions) // Pass job description and resume text.
	if err != nil {
		// Log the error, and perhaps send a message to the user saying
		// that Gemini processing failed, but their message *was* saved.
		fmt.Printf("Gemini API call failed: %v\n", err)
		responseText = "Gemini processing failed. Your message has been saved." // Fallback
	}
	fmt.Println(responseText)

	// 4. Create a new Message with the *Gemini response*.
	message := authmodel.Message{
		SenderID:    senderID,     // Company user
		ReceiverID:  receiverID,   // Applicant user
		MessageText: responseText, // Gemini's response
	}

	result := s.DB.Create(&message)
	if result.Error != nil {
		return "", fmt.Errorf("failed to create message: %w", result.Error)
	}

	return responseText, nil // Return the processed text

}

func (s *MessageService) GetUserMessagesWithGemini(userID uint, jobID uint) ([]authmodel.Message, error) {
	var messages []authmodel.Message

	err := s.DB.
		Preload("Sender").                                                                                                    // Preload sender details
		Preload("Receiver").                                                                                                  // Preload receiver details
		Joins("JOIN job_applications ON messages.receiver_id = job_applications.user_id").                                    //Join tables
		Where("job_applications.job_id = ? AND (messages.sender_id = ? OR messages.receiver_id = ?)", jobID, userID, userID). // Get all relate message
		Order("messages.created_at ASC").                                                                                     // Order by creation time (oldest first)
		Find(&messages).Error

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve messages: %w", err)
	}
	return messages, nil
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

func (s *MessageService) InteractWithGemini(senderID, receiverID uint, messageText string, jobID uint) (*authmodel.Message, *authmodel.Message, error) {
	var geminiResponse string
	var err error
	var geminiQuestion *string // Declare question outside the if block

	if jobID != 0 {
		var application jobmodel.JobApplication
		err = s.DB.
			Preload("User").
			Preload("JobPost.User").
			Where("job_id = ? AND user_id = ? AND deleted_at IS NULL", jobID, senderID).
			First(&application).Error

		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return nil, nil, fmt.Errorf("no application found for job ID %d and user ID %d", jobID, receiverID)
			}
			return nil, nil, fmt.Errorf("failed to retrieve application: %w", err)
		}

		extractedText, extractErr := s.PdfExtractor.ExtractText(application.ResumeFile)
		if extractErr != nil {
			return nil, nil, fmt.Errorf("failed to extract from PDF: %w", extractErr)
		}

		// --- Get the LATEST message ---
		var secondLastMessage authmodel.Message
		// Find the second-to-last message between these two users.
		err = s.DB.
			Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)", senderID, receiverID, receiverID, senderID).
			Order("created_at DESC"). // Order by creation time, newest first
			Offset(1).                // Skip the *first* (most recent) result
			Limit(1).                 // Only take *one* result (the second-to-last)
			First(&secondLastMessage).Error

		var lastMessageText string // Variable to hold the last message (or an empty string if none)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				// No previous messages.  That's OK.
				lastMessageText = "" // Use empty string as the "previous question"
			} else {
				return nil, nil, fmt.Errorf("failed to retrieve second-to-last message: %w", err)
			}
		} else {
			lastMessageText = secondLastMessage.MessageText // Get text of the *last* message
		}

		// Get response from Gemini
		geminiResponse, _, geminiQuestion, err = s.GeminiService.GenerateContentWithHistory(application.JobPost.Description, extractedText, "User: "+messageText, lastMessageText)
		if err != nil {
			fmt.Printf("Gemini API error: %v\n", err)
			geminiResponse = "AI response failed."
		}

	} else {
		geminiResponse, err = s.GeminiService.InteractWithUser(messageText)
		if err != nil {
			fmt.Printf("Gemini API error: %v\n", err)
			geminiResponse = "AI response failed."
		}
	}

	// --- Transaction Start ---
	tx := s.DB.Begin()
	if tx.Error != nil {
		return nil, nil, fmt.Errorf("failed to start transaction: %w", tx.Error)
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. Create the USER'S message.
	userMessage := authmodel.Message{
		SenderID:    senderID,
		ReceiverID:  receiverID,  // Receiver is initially the other user (could be Gemini)
		MessageText: messageText, // Original user message
	}
	if err := tx.Create(&userMessage).Error; err != nil {
		tx.Rollback()
		return nil, nil, fmt.Errorf("failed to create user message: %w", err)
	}

	// 2. Create the GEMINI response message (Summary).
	aiMessage := authmodel.Message{
		SenderID:    receiverID,     // Gemini is the sender
		ReceiverID:  senderID,       // User is the receiver
		MessageText: geminiResponse, // Response from Gemini (Summary)
	}
	if err := tx.Create(&aiMessage).Error; err != nil {
		tx.Rollback()
		return nil, nil, fmt.Errorf("failed to create AI message: %w", err)
	}

	// 3.  Create a *separate* message for Gemini's QUESTIONS (if any).
	if geminiQuestion != nil && *geminiQuestion != "" && *geminiQuestion != "None" {
		questionMessage := authmodel.Message{
			SenderID:    receiverID,
			ReceiverID:  senderID,
			MessageText: *geminiQuestion,
		}
		if err := tx.Create(&questionMessage).Error; err != nil {
			tx.Rollback()
			return nil, nil, fmt.Errorf("failed to create question message: %w", err)
		}
	}

	// --- Transaction Commit ---
	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		return nil, nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return &userMessage, &aiMessage, nil
}
