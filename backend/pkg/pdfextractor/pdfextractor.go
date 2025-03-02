package pdfextractor

import (
	"bytes"
	"io"

	"github.com/ledongthuc/pdf"
)

// IPdfExtractor interface for extracting text from PDF.
type IPdfExtractor interface {
	ExtractText(filePath string) (string, error)
}

// PdfExtractor implements IPdfExtractor.
type PdfExtractor struct{}

// NewPdfExtractor creates a new PdfExtractor.
func NewPdfExtractor() *PdfExtractor {
	return &PdfExtractor{}
}

// ExtractText extracts text from a PDF file.
func (p *PdfExtractor) ExtractText(path string) (string, error) {
	f, r, err := pdf.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()

	var buf bytes.Buffer
	b, err := r.GetPlainText()
	if err != nil {
		return "", err
	}
	_, err = io.Copy(&buf, b)
	if err != nil {
		return "", err
	}
	return buf.String(), nil
}
