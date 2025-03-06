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
// Update the interface to return BOTH the text and the score.
type IGeminiService interface {
	GenerateContent(jobDescription, resumeText string) (string, *float64, *string, error) // Returns text, score, questions, and error
	InteractWithUser(userMessage string) (string, error)
	GenerateContentWithHistory(jobDescription, resumeText, conversationHistory string, questions string) (string, *float64, *string, error)
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

// GenerateContent interacts with the Gemini API and extracts both text and score.
func (s *GeminiService) GenerateContent(jobDescription, resumeText string) (string, *float64, *string, error) {
	endpoint := s.apiEndpoint + s.apiKey
	// Construct a prompt that asks for BOTH a summary AND a score.
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

	// Extract the generated text and score. Handle potential errors robustly.
	if candidates, ok := responseBody["candidates"].([]interface{}); ok && len(candidates) > 0 {
		if candidate, ok := candidates[0].(map[string]interface{}); ok {
			if content, ok := candidate["content"].(map[string]interface{}); ok {
				if parts, ok := content["parts"].([]interface{}); ok && len(parts) > 0 {
					if part, ok := parts[0].(map[string]interface{}); ok {
						if textVal, ok := part["text"].(string); ok {
							// Text extraction successful, now try to get the score.

							// Use a regular expression to find the score.  This is more robust.
							reScore := regexp.MustCompile(`SCORE:\s*(\d+(\.\d+)?)`)
							matchScore := reScore.FindStringSubmatch(textVal)
							var score *float64
							if len(matchScore) > 1 {
								scoreVal, err := strconv.ParseFloat(matchScore[1], 64) //Parse string to float
								if err == nil {                                        // if no error
									score = &scoreVal // Use the address of scoreVal and assign to the pointer
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
	// If NO score given, we just return the text
	return "", nil, nil, fmt.Errorf("could not extract text from API response: %v", responseBody)
}

// InteractWithUser handles general user interactions with Gemini.
func (s *GeminiService) InteractWithUser(userMessage string) (string, error) {
	endpoint := s.apiEndpoint + s.apiKey
	prompt := fmt.Sprintf("User: %s\nGemini:", userMessage) // Basic prompt

	requestBody, err := json.Marshal(map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{
						"text": prompt,
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
		bodyBytes, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("API request failed with status %s: %s", resp.Status, string(bodyBytes))
	}

	var responseBody map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseBody); err != nil {
		return "", fmt.Errorf("error decoding API response: %w", err)
	}

	// Extract and return the generated text (similar to GenerateContent, but simplified)
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

// GenerateContentWithHistory takes the job description, resume, and conversation history.
func (s *GeminiService) GenerateContentWithHistory(jobDescription, resumeText, conversationHistory, question string) (string, *float64, *string, error) {
	endpoint := s.apiEndpoint + s.apiKey

	prompt := fmt.Sprintf(`
**Job Description:**
%s

**Resume:**
%s

**Previous Conversation History:**
%s

**Applicant's Answers to Previous Questions:**
%s

**Instructions:**

Please analyze the resume in the context of the job description. Consider the ENTIRE conversation history, including the applicant's answers to previous questions.

Provide the following:

1.  Summary: A concise summary of the applicant's qualifications *in light of their answers*.
2.  Score: A numerical score from 0.0 to 1.0 representing the overall match between the resume (and answers) and the job description.  Place this score on a line that starts with "SCORE: ".
3.  Questions: If there are *any* remaining qualifications that are unclear or missing, list specific questions to ask the applicant.  Place these questions on a line that start with "QUESTIONS: ".  If no further questions are needed, write "QUESTIONS: None".

`, jobDescription, resumeText, conversationHistory, question)

	requestBody, err := json.Marshal(map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{
						"text": prompt,
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

	fmt.Printf("Raw Gemini Response: %+v\n", responseBody)

	var summary string
	var score *float64
	var questions *string

	if candidates, ok := responseBody["candidates"].([]interface{}); ok && len(candidates) > 0 {
		if candidate, ok := candidates[0].(map[string]interface{}); ok {
			if content, ok := candidate["content"].(map[string]interface{}); ok {
				if parts, ok := content["parts"].([]interface{}); ok && len(parts) > 0 {
					if part, ok := parts[0].(map[string]interface{}); ok {
						if textVal, ok := part["text"].(string); ok {
							// --- Extract Score (Case-Insensitive) ---
							reScore := regexp.MustCompile(`(?i)SCORE:\s*(\d+(\.\d+)?)`) // (?i) for case-insensitivity
							matchScore := reScore.FindStringSubmatch(textVal)
							if len(matchScore) > 1 {
								if scoreVal, err := strconv.ParseFloat(matchScore[1], 64); err == nil {
									score = &scoreVal
								}
							}

							// --- Extract Questions (Case-Insensitive and Multiline) ---
							reQuestions := regexp.MustCompile(`(?i)QUESTIONS:\s*(.*)`) // (?i) for case-insensitivity
							matchQuestions := reQuestions.FindStringSubmatch(textVal)
							if len(matchQuestions) > 1 {
								questionStr := strings.TrimSpace(matchQuestions[1])
								questions = &questionStr
							}

							// --- Extract Summary (Case-Insensitive and Multiline) ---
							reSummary := regexp.MustCompile(`(?is)Summary:(.*)(?:SCORE:|QUESTIONS:)`) // (?s) for multiline, (?:...) for non-capturing group
							matchSummary := reSummary.FindStringSubmatch(textVal)
							if len(matchSummary) > 1 {
								summary = strings.TrimSpace(matchSummary[1])
							} else {
								// If "Summary:" not found, assume the entire text (before SCORE/QUESTIONS) is the summary
								summary = textVal
								summary = reScore.ReplaceAllString(summary, "")     // Remove SCORE line
								summary = reQuestions.ReplaceAllString(summary, "") // Remove QUESTIONS section
								summary = strings.TrimSpace(summary)                // Remove leading/trailing space
							}
							fmt.Println("----------")
							fmt.Println(*questions)
							return summary, score, questions, nil // Return extracted values
						}
					}
				}
			}
		}
	}

	return "", nil, nil, fmt.Errorf("could not extract data from API response: %v", responseBody)
}
