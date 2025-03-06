// messagehandler/messagehandler.go
package messagehandler

import (
	"backend/pkg/service/messageservice"
	"fmt"
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

type IMessageHandler interface {
	SendMessage(c *fiber.Ctx) error
	ViewMessages(c *fiber.Ctx) error
	GetMessage(c *fiber.Ctx) error
	RespondToApplicant(c *fiber.Ctx) error
}

type MessageHandler struct {
	MessageService messageservice.IMessageService
}

func NewMessageHandler(messageService messageservice.IMessageService) *MessageHandler {
	return &MessageHandler{MessageService: messageService}
}

// SendMessage handles POST /api/messages
func (h *MessageHandler) SendMessage(c *fiber.Ctx) error {
	senderID, ok := c.Locals("userID").(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	type SendMessageRequest struct {
		ReceiverID  uint   `json:"receiver_id" binding:"required"`
		MessageText string `json:"message_text" binding:"required"`
		JobID       uint   `json:"job_id"`
	}

	var req SendMessageRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	// Call InteractWithGemini.  This now handles *both* sending to Gemini
	// *and* saving both messages.
	userMessage, aiMessage, err := h.MessageService.InteractWithGemini(senderID, req.ReceiverID, req.MessageText, req.JobID)
	// fmt.Println(userMessage)
	fmt.Println("====================================")
	// fmt.Println(aiMessage)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to send message"})
	}

	// Return both messages to the client.
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"user_message": userMessage,
		"ai_message":   aiMessage,
	})
}

// ViewMessages handles GET /api/messages/:userId
func (h *MessageHandler) ViewMessages(c *fiber.Ctx) error {
	userIDStr := c.Params("userId") // Get as string first
	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}

	// Get logged-in user and role from the context (set by middleware).
	loggedInUserID, ok := c.Locals("userID").(uint) // Retrieve and assert type
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized - User ID not found"})
	}
	loggedInUserType, ok := c.Locals("userType").(string) // Retrieve and assert type
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized - User Type not found"})
	}

	// Authorization logic
	if loggedInUserType == "applicant" {
		// Applicants can ONLY see their own messages.
		if uint(userID) != loggedInUserID {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Forbidden"})
		}
	} else if loggedInUserType == "company" {
		// For company users, we use the service layer to check ownership.
		messages, err := h.MessageService.GetMessagesForUser(uint(userID), loggedInUserID, loggedInUserType) // Pass all info
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve messages"})
		}
		return c.Status(fiber.StatusOK).JSON(messages) // Return the result directly.

	} else {
		// Handle other user types (or deny access)
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Forbidden - Invalid user type"})
	}

	// If we get here, it's either an applicant viewing their own messages,
	// or a company user and the check happened in the service layer.

	messages, err := h.MessageService.GetMessagesForUser(uint(userID), loggedInUserID, loggedInUserType) // Pass loggedInUserID
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve messages"})
	}

	return c.Status(fiber.StatusOK).JSON(messages)
}

func (h *MessageHandler) GetMessage(c *fiber.Ctx) error {
	messageID, err := strconv.ParseUint(c.Params("messageId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid message ID"})
	}
	message, err := h.MessageService.GetMessageByID(uint(messageID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to retrieve message"})
	}
	if message == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Message not found"})
	}
	return c.Status(fiber.StatusOK).JSON(message)

}

func (h *MessageHandler) RespondToApplicant(c *fiber.Ctx) error {
	// 1. Get the sender's ID (company user) from the JWT.
	senderID, ok := c.Locals("userID").(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	senderUserType, ok := c.Locals("userType").(string)
	if !ok || senderUserType != "company" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Forbidden"})
	}

	// 2. Get the job ID from the URL parameter.
	jobID, err := strconv.ParseUint(c.Params("jobId"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid job ID"})
	}

	// 3. Get applicant ID from request body
	var req struct {
		ReceiverID uint   `json:"receiver_id" binding:"required"` // Use a struct for clarity
		Response   string `json:"response" binding:"required"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}
	// 4. Call the service to process and send the message.
	responseText, err := h.MessageService.ProcessAndSendMessage(senderID, req.ReceiverID, req.Response, uint(jobID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": fmt.Sprintf("Failed to send message: %v", err)})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "Response sent successfully", "response": responseText})
}

// Helper function to get user id from jwt token (Same as previous GetUserProfile)
func getUserIDFromToken(c *fiber.Ctx) (uint, error) {
	user := c.Locals("user") // Get the user object from context (set by middleware)
	if user == nil {
		return 0, fmt.Errorf("no user in context")
	}

	token, ok := user.(*jwt.Token) // Assert to *jwt.Token  <-- CORRECT TYPE
	if !ok {
		return 0, fmt.Errorf("invalid token type")
	}

	claims, ok := token.Claims.(jwt.MapClaims) // Get the claims
	if !ok {
		return 0, fmt.Errorf("invalid claims type")
	}

	userIDFloat, ok := claims["user_id"].(float64) // JWT IDs are often floats
	if !ok {
		return 0, fmt.Errorf("invalid user ID format in token")
	}
	userID := uint(userIDFloat) // Convert to uint

	return userID, nil
}
