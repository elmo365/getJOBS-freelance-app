# BotsJobsConnect Manual PDF Generator
# This script converts Markdown manuals to PDF format

param(
    [string]$Manual = "all"  # Options: "all", "user", "company", "admin", "admin-user"
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-ColorOutput Cyan "=========================================="
Write-ColorOutput Cyan "BotsJobsConnect PDF Generator"
Write-ColorOutput Cyan "=========================================="
Write-Output ""

# Check if pandoc is installed
$pandocPath = Get-Command pandoc -ErrorAction SilentlyContinue
if (-not $pandocPath) {
    Write-ColorOutput Yellow "⚠️  Pandoc not found. Installing instructions:"
    Write-Output ""
    Write-Output "Option 1: Install Pandoc (Recommended)"
    Write-Output "  Download: https://pandoc.org/installing.html"
    Write-Output "  Or use: winget install --id JohnMacFarlane.Pandoc"
    Write-Output ""
    Write-Output "Option 2: Use Online Converter"
    Write-Output "  Visit: https://www.markdowntopdf.com/"
    Write-Output "  Or: https://dillinger.io/ (Export as PDF)"
    Write-Output ""
    Write-Output "Option 3: Use VS Code Extension"
    Write-Output "  Install: 'Markdown PDF' extension"
    Write-Output "  Right-click .md file → 'Markdown PDF: Export (pdf)'"
    Write-Output ""
    
    # Check if we can use Python with markdown-pdf
    $pythonPath = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonPath) {
        Write-ColorOutput Green "✓ Python found. Checking for markdown-pdf..."
        $mdpdf = python -c "import markdown_pdf; print('installed')" 2>&1
        if ($mdpdf -match "installed") {
            Write-ColorOutput Green "✓ markdown-pdf Python package found!"
            $usePython = $true
        } else {
            Write-ColorOutput Yellow "Installing markdown-pdf Python package..."
            pip install markdown-pdf 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $usePython = $true
                Write-ColorOutput Green "✓ markdown-pdf installed!"
            }
        }
    }
    
    if (-not $usePython) {
        Write-ColorOutput Red "❌ No PDF conversion tool found."
        Write-Output ""
        Write-Output "Please install one of the options above and run this script again."
        exit 1
    }
}

# Set paths
$docsPath = Join-Path $PSScriptRoot "..\docs"
$outputPath = Join-Path $PSScriptRoot "..\docs\pdfs"
$manuals = @{
    "user" = "USER_MANUAL.md"
    "company" = "COMPANY_MANUAL.md"
    "admin" = "ADMIN_GUIDE.md"
    "admin-user" = "ADMIN_USER_MANUAL.md"
    "ai-roadmap" = "AI_ROADMAP.md"
}

# Create output directory
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    Write-ColorOutput Green "✓ Created output directory: $outputPath"
}

# Function to convert with pandoc
function Convert-WithPandoc($inputFile, $outputFile) {
    Write-Output "Converting: $inputFile"
    pandoc "$inputFile" `
        -o "$outputFile" `
        --pdf-engine=wkhtmltopdf `
        -V geometry:margin=1in `
        -V fontsize=11pt `
        --toc `
        --toc-depth=2 `
        -V colorlinks=true `
        -V linkcolor=blue `
        -V urlcolor=blue
}

# Function to convert with Python markdown-pdf
function Convert-WithPython($inputFile, $outputFile) {
    Write-Output "Converting: $inputFile"
    $script = @"
import markdown_pdf
markdown_pdf.convert_markdown_to_pdf("$inputFile", "$outputFile")
"@
    python -c $script
}

# Determine which manuals to convert
$toConvert = @()
if ($Manual -eq "all") {
    $toConvert = $manuals.Keys
} else {
    if ($manuals.ContainsKey($Manual)) {
        $toConvert = @($Manual)
    } else {
        Write-ColorOutput Red "❌ Unknown manual: $Manual"
        Write-Output "Available: all, user, company, admin, admin-user, ai-roadmap"
        exit 1
    }
}

# Convert manuals
$converted = 0
$failed = 0

foreach ($key in $toConvert) {
    $inputFile = Join-Path $docsPath $manuals[$key]
    $outputFile = Join-Path $outputPath ($manuals[$key] -replace "\.md$", ".pdf")
    
    if (-not (Test-Path $inputFile)) {
        Write-ColorOutput Yellow "⚠️  File not found: $inputFile"
        $failed++
        continue
    }
    
    try {
        if ($pandocPath) {
            Convert-WithPandoc $inputFile $outputFile
        } elseif ($usePython) {
            Convert-WithPython $inputFile $outputFile
        }
        
        if (Test-Path $outputFile) {
            Write-ColorOutput Green "✓ Generated: $outputFile"
            $converted++
        } else {
            Write-ColorOutput Red "❌ Failed to generate: $outputFile"
            $failed++
        }
    } catch {
        Write-ColorOutput Red "❌ Error converting $inputFile : $_"
        $failed++
    }
    Write-Output ""
}

# Summary
Write-ColorOutput Cyan "=========================================="
Write-ColorOutput Cyan "Summary"
Write-ColorOutput Cyan "=========================================="
Write-ColorOutput Green "✓ Converted: $converted"
if ($failed -gt 0) {
    Write-ColorOutput Red "❌ Failed: $failed"
}
Write-Output ""
Write-Output "PDFs saved to: $outputPath"
Write-Output ""

