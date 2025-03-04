// messagehandler/messagehandler.go
package messagehandler

import (
	"backend/pkg/service/messageservice"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

type IMessageHandler interface {
	SendMessage(c *fiber.Ctx) error
	ViewMessages(c *fiber.Ctx) error
	GetMessage(c *fiber.Ctx) error
}

type MessageHandler struct {
	MessageService messageservice.IMessageService
}

func NewMessageHandler(messageService messageservice.IMessageService) *MessageHandler {
	return &MessageHandler{MessageService: messageService}
}

// SendMessage handles POST /api/messages
func (h *MessageHandler) SendMessage(c *fiber.Ctx) error {
	// Get sender ID from JWT (authenticated user).
	senderID, ok := c.Locals("userID").(uint) // Get and assert type
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	// Define a request struct for the message body.
	type SendMessageRequest struct {
		ReceiverID  uint   `json:"receiver_id" binding:"required"`
		MessageText string `json:"message_text" binding:"required"`
	}

	var req SendMessageRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	// Call the service to send the message.
	message, err := h.MessageService.SendMessage(senderID, req.ReceiverID, req.MessageText)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to send message"})
	}

	return c.Status(fiber.StatusCreated).JSON(message) // Return the created message
}

// ViewMessages handles GET /api/messages/:userId
// ViewMessages handles GET /api/messages/:userId with authorization checks.
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
