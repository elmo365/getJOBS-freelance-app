# PDF Generation Guide

This guide explains how to generate PDF versions of the BotsJobsConnect manuals.

## Quick Start

### Option 1: Using PowerShell Script (Windows)

```powershell
# Generate all PDFs
.\scripts\generate_pdfs.ps1

# Generate specific manual
.\scripts\generate_pdfs.ps1 -Manual user
.\scripts\generate_pdfs.ps1 -Manual company
.\scripts\generate_pdfs.ps1 -Manual admin-user
```

### Option 2: Using Pandoc (Recommended)

**Install Pandoc:**
```powershell
# Using winget
winget install --id JohnMacFarlane.Pandoc

# Or download from: https://pandoc.org/installing.html
```

**Generate PDFs:**
```powershell
cd docs
pandoc USER_MANUAL.md -o pdfs/USER_MANUAL.pdf --toc --pdf-engine=wkhtmltopdf
pandoc COMPANY_MANUAL.md -o pdfs/COMPANY_MANUAL.pdf --toc --pdf-engine=wkhtmltopdf
pandoc ADMIN_USER_MANUAL.md -o pdfs/ADMIN_USER_MANUAL.pdf --toc --pdf-engine=wkhtmltopdf
```

**Note:** You may also need `wkhtmltopdf`:
```powershell
winget install --id wkhtmltopdf.wkhtmltopdf
```

### Option 3: Using VS Code Extension

1. Install **"Markdown PDF"** extension in VS Code
2. Open any `.md` file in `docs/` folder
3. Right-click → **"Markdown PDF: Export (pdf)"**
4. PDF will be saved in the same directory

### Option 4: Online Converters

1. **Dillinger.io:**
   - Visit: https://dillinger.io/
   - Paste Markdown content
   - Click "Export as" → "PDF"

2. **Markdown to PDF:**
   - Visit: https://www.markdowntopdf.com/
   - Upload `.md` file
   - Download PDF

3. **GitHub:**
   - View `.md` file on GitHub
   - Print page (Ctrl+P)
   - Save as PDF

### Option 5: Using Python

```bash
# Install markdown-pdf
pip install markdown-pdf

# Convert
python -c "import markdown_pdf; markdown_pdf.convert_markdown_to_pdf('docs/USER_MANUAL.md', 'docs/pdfs/USER_MANUAL.pdf')"
```

## Manual List

Available manuals to convert:

- `USER_MANUAL.md` - Job Seeker Manual
- `COMPANY_MANUAL.md` - Company & Employer Manual
- `ADMIN_USER_MANUAL.md` - Administrator User Manual
- `ADMIN_GUIDE.md` - Technical Admin Reference
- `AI_ROADMAP.md` - AI Features Roadmap

## Output Location

PDFs will be saved to: `docs/pdfs/`

## Troubleshooting

### Pandoc not found
- Install Pandoc from https://pandoc.org/installing.html
- Or use one of the alternative methods above

### PDF engine not found
- Install wkhtmltopdf: `winget install --id wkhtmltopdf.wkhtmltopdf`
- Or use: `--pdf-engine=pdflatex` (requires LaTeX)

### Formatting issues
- Check that all images are accessible
- Ensure relative links are correct
- Try different PDF engines

## Batch Conversion Script

For convenience, use the PowerShell script:

```powershell
# All manuals
.\scripts\generate_pdfs.ps1 -Manual all

# Individual manuals
.\scripts\generate_pdfs.ps1 -Manual user
.\scripts\generate_pdfs.ps1 -Manual company
.\scripts\generate_pdfs.ps1 -Manual admin-user
```

---

*Last Updated: December 2024*

