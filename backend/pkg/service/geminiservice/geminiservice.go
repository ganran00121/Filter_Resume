package geminiservice

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// IGeminiService interface
type IGeminiService interface {
	GenerateContent(text string) (string, error)
}

// GeminiService struct
type GeminiService struct {
	apiKey      string
	apiEndpoint string
}

// NewGeminiService creates a new GeminiService instance.
func NewGeminiService(apiKey, apiEndpoint string) *GeminiService {
	//Check API key
	if apiKey == "" {
		panic("GEMINI_API_KEY environment variable not set") //Panic if no API key.
	}
	return &GeminiService{apiKey: apiKey, apiEndpoint: apiEndpoint}
}

// GenerateContent interacts with the Gemini API.
func (s *GeminiService) GenerateContent(text string) (string, error) {
	endpoint := s.apiEndpoint + s.apiKey //Compose the API endpoint
	requestBody, err := json.Marshal(map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{
						"text": text,
					},
				},
			},
		},
	})
	if err != nil {
		return "", fmt.Errorf("error marshalling request body: %w", err)
	}

	resp, err := http.Post(endpoint, "application/json", bytes.NewBuffer(requestBody))
	if err != nil {
		return "", fmt.Errorf("error making API request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body) // Read the body for the error message
		return "", fmt.Errorf("API request failed with status %s: %s", resp.Status, string(bodyBytes))
	}

	var responseBody map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseBody); err != nil {
		return "", fmt.Errorf("error decoding API response: %w", err)
	}

	// Extract the generated text. Handle potential errors robustly.
	if candidates, ok := responseBody["candidates"].([]interface{}); ok && len(candidates) > 0 {
		if candidate, ok := candidates[0].(map[string]interface{}); ok {
			if content, ok := candidate["content"].(map[string]interface{}); ok {
				if parts, ok := content["parts"].([]interface{}); ok && len(parts) > 0 {
					if part, ok := parts[0].(map[string]interface{}); ok {
						if text, ok := part["text"].(string); ok {
							return text, nil
						}
					}
				}
			}
		}
	}

	return "", fmt.Errorf("could not extract text from API response: %v", responseBody)
}
