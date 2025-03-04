package geminiservice

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"strings"
)

// IGeminiService interface
type IGeminiService interface {
	GenerateContent(jobDescription, resumeText string) (string, *float64, *string, error) // Return summary, score, questions, and error
}

// GeminiService struct
type GeminiService struct {
	apiKey      string
	apiEndpoint string
}

// NewGeminiService creates a new GeminiService instance.
func NewGeminiService(apiKey, apiEndpoint string) *GeminiService {
	if apiKey == "" {
		panic("GEMINI_API_KEY environment variable not set")
	}
	return &GeminiService{apiKey: apiKey, apiEndpoint: apiEndpoint}
}

func (s *GeminiService) GenerateContent(jobDescription, resumeText string) (string, *float64, *string, error) {
	endpoint := s.apiEndpoint + s.apiKey
	// Modified prompt to ask for questions.  VERY IMPORTANT.
	prompt := fmt.Sprintf(`Job Description:
%s

Resume:
%s

Please provide a summary of the resume, AND, on a separate line, provide a numerical score from 0.0 to 1.0 indicating how well the resume matches the job description. The score should be on a line that starts with "SCORE: ".
Also, list any missing qualifications from the resume compared to the job description, and generate questions to ask the applicant about these missing qualifications.  Format the questions on a separate line that starts with "QUESTIONS: ".  For example:

Summary: This is a strong resume...
SCORE: 0.9
QUESTIONS: 1. The job description mentions experience with X, but your resume doesn't include it.  Can you elaborate on your experience with X? 2. ...
`, jobDescription, resumeText)

	requestBody, err := json.Marshal(map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{
						"text": prompt, // Use the combined prompt
					},
				},
			},
		},
	})
	if err != nil {
		return "", nil, nil, fmt.Errorf("error marshalling request body: %w", err)
	}

	resp, err := http.Post(endpoint, "application/json", bytes.NewBuffer(requestBody))
	if err != nil {
		return "", nil, nil, fmt.Errorf("error making API request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return "", nil, nil, fmt.Errorf("API request failed with status %s: %s", resp.Status, string(bodyBytes))
	}

	var responseBody map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseBody); err != nil {
		return "", nil, nil, fmt.Errorf("error decoding API response: %w", err)
	}

	// Extract the generated text, score, and questions.
	if candidates, ok := responseBody["candidates"].([]interface{}); ok && len(candidates) > 0 {
		if candidate, ok := candidates[0].(map[string]interface{}); ok {
			if content, ok := candidate["content"].(map[string]interface{}); ok {
				if parts, ok := content["parts"].([]interface{}); ok && len(parts) > 0 {
					if part, ok := parts[0].(map[string]interface{}); ok {
						if textVal, ok := part["text"].(string); ok {
							// --- Extract Score (as before) ---
							reScore := regexp.MustCompile(`SCORE:\s*(\d+(\.\d+)?)`)
							matchScore := reScore.FindStringSubmatch(textVal)
							var score *float64
							if len(matchScore) > 1 {
								scoreVal, err := strconv.ParseFloat(matchScore[1], 64)
								if err == nil {
									score = &scoreVal
								}
							}

							// --- Extract Questions ---
							reQuestions := regexp.MustCompile(`QUESTIONS:\s*(.*)`)
							matchQuestions := reQuestions.FindStringSubmatch(textVal)
							var questions *string
							if len(matchQuestions) > 1 {
								questionStr := strings.TrimSpace(matchQuestions[1]) // Get the captured group and trim whitespace
								questions = &questionStr                            // Take the address
							}
							// Clean the text (remove SCORE and QUESTIONS lines)
							cleanText := reScore.ReplaceAllString(textVal, "")
							cleanText = reQuestions.ReplaceAllString(cleanText, "")
							cleanText = strings.TrimSpace(cleanText) // Remove leading/trailing whitespace

							return cleanText, score, questions, nil // Return summary, score, questions

						}
					}
				}
			}
		}
	}

	return "", nil, nil, fmt.Errorf("could not extract text from API response: %v", responseBody)
}
