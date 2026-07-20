---
name: pdf-reader
description: Extract text from PDF files. Use when user asks to read, extract text from, or summarize a PDF.
---

## Usage

Read a PDF and extract its text content.

**Tool:** `pdf-reader.sh <path-to-pdf>`

## Dependencies

Requires `pdftotext` from poppler:
```bash
brew install poppler
```

## Examples

**Extract all text from a PDF:**
```
pdf-reader.sh document.pdf
```

**Extract and search for specific content:**
```
pdf-reader.sh document.pdf | grep "keyword"
```

## Notes

- Outputs to stdout, pipe as needed
- May lose formatting from complex layouts
- Images and tables are not preserved
- Large PDFs may take time to process
