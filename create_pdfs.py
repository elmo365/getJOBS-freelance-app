#!/usr/bin/env python3
"""
Convert markdown guide files to professional PDF documents
"""

import os
import sys
from pathlib import Path

# Try to import required libraries
try:
    import markdown
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch, cm
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
except ImportError:
    print("Installing required packages...")
    os.system("python -m pip install markdown reportlab -q")
    import markdown
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch, cm
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY

def read_markdown(filepath):
    """Read markdown file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def markdown_to_html(md_content):
    """Convert markdown to HTML"""
    return markdown.markdown(md_content, extensions=['extra', 'toc'])

def html_to_pdf_with_pdfkit(html_content, output_file):
    """Convert HTML to PDF using pdfkit"""
    try:
        import pdfkit
        pdfkit.from_string(html_content, output_file, options={
            'page-size': 'A4',
            'margin-top': '20mm',
            'margin-right': '15mm',
            'margin-bottom': '20mm',
            'margin-left': '15mm',
            'enable-local-file-access': None
        })
        return True
    except:
        return False

def simple_md_to_pdf(md_file, pdf_file):
    """Simple markdown to PDF conversion using reportlab"""
    from io import StringIO
    
    # Read markdown
    with open(md_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Create PDF
    doc = SimpleDocTemplate(
        pdf_file,
        pagesize=A4,
        topMargin=20*mm,
        bottomMargin=20*mm,
        leftMargin=15*mm,
        rightMargin=15*mm,
        title=Path(md_file).stem
    )
    
    # Define styles
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor('#1f4788'),
        spaceAfter=12,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading1_style = ParagraphStyle(
        'CustomHeading1',
        parent=styles['Heading1'],
        fontSize=16,
        textColor=colors.HexColor('#1f4788'),
        spaceAfter=6,
        spaceBefore=12,
        fontName='Helvetica-Bold'
    )
    
    heading2_style = ParagraphStyle(
        'CustomHeading2',
        parent=styles['Heading2'],
        fontSize=13,
        textColor=colors.HexColor('#2b5aa0'),
        spaceAfter=6,
        spaceBefore=10,
        fontName='Helvetica-Bold'
    )
    
    heading3_style = ParagraphStyle(
        'CustomHeading3',
        parent=styles['Heading3'],
        fontSize=11,
        textColor=colors.HexColor('#2b5aa0'),
        spaceAfter=4,
        spaceBefore=8,
        fontName='Helvetica-Bold'
    )
    
    normal_style = ParagraphStyle(
        'CustomNormal',
        parent=styles['Normal'],
        fontSize=10,
        alignment=TA_JUSTIFY,
        spaceAfter=6
    )
    
    # Build story
    story = []
    current_line = 0
    
    for i, line in enumerate(lines):
        line = line.rstrip()
        
        if not line:
            story.append(Spacer(1, 6))
            continue
        
        # Detect heading levels
        if line.startswith('# ') and not line.startswith('# '):
            text = line[2:].strip()
            story.append(Paragraph(text, title_style))
            story.append(Spacer(1, 8))
        elif line.startswith('## '):
            text = line[3:].strip()
            story.append(Paragraph(text, heading1_style))
            story.append(Spacer(1, 6))
        elif line.startswith('### '):
            text = line[4:].strip()
            story.append(Paragraph(text, heading2_style))
            story.append(Spacer(1, 4))
        elif line.startswith('#### '):
            text = line[5:].strip()
            story.append(Paragraph(text, heading3_style))
            story.append(Spacer(1, 3))
        elif line.startswith('- ') or line.startswith('* '):
            text = '• ' + line[2:].strip()
            story.append(Paragraph(text, normal_style))
        else:
            # Regular paragraph
            clean_text = line.replace('**', '').replace('*', '').replace('_', '').replace('`', '')
            if clean_text.strip():
                story.append(Paragraph(clean_text, normal_style))
    
    # Add page breaks for readability
    if len(story) > 100:
        # Insert page breaks every 50 elements
        new_story = []
        for i, element in enumerate(story):
            new_story.append(element)
            if i > 0 and i % 100 == 0 and i < len(story) - 1:
                new_story.append(PageBreak())
        story = new_story
    
    # Build PDF
    try:
        doc.build(story)
        return True
    except Exception as e:
        print(f"Error building PDF: {e}")
        return False

# Try HTML-based approach with available tools
def create_pdf_from_html(html_file, pdf_file):
    """Try to create PDF from HTML using available tools"""
    try:
        # Try using wkhtmltopdf if available
        result = os.system(f'wkhtmltopdf "{html_file}" "{pdf_file}" 2>nul')
        if result == 0:
            return True
    except:
        pass
    
    try:
        # Try using edge/chrome
        import subprocess
        subprocess.run([
            'cmd', '/c', 'start', '/wait',
            'msedge', f'--headless', f'--disable-gpu', 
            f'--print-to-pdf={pdf_file}', f'file:///{os.path.abspath(html_file)}'
        ], timeout=30)
        if os.path.exists(pdf_file) and os.path.getsize(pdf_file) > 0:
            return True
    except:
        pass
    
    return False

def main():
    """Main conversion function"""
    guides = [
        # User Manuals
        'ADMIN_GUIDE_COMPLETE.md',
        'GETTING_STARTED_COMMON_FEATURES.md',
        'USER_MANUAL_JOB_SEEKERS.md',
        'USER_MANUAL_EMPLOYERS.md',
        'USER_MANUAL_TRAINERS.md',
        # Feature Guides (Batch format)
        'FEATURE_GUIDE_BATCH1_JOBSEEKER.md',
        'FEATURE_GUIDE_BATCH2_EMPLOYER.md',
        'FEATURE_GUIDE_BATCH3_TRAINER.md',
        'FEATURE_GUIDE_BATCH4_ADMIN.md',
        'FEATURE_GUIDE_BATCH5_COMMON.md',
        # Production Readiness Analysis
        'JOB_WORKFLOW_GAPS_ANALYSIS.md',
        'PRODUCTION_READINESS_WORKFLOW_ANALYSIS.md'
    ]
    
    current_dir = Path.cwd()
    success_count = 0
    
    print("=" * 60)
    print("Converting Markdown Guides to PDF")
    print("=" * 60)
    
    for guide in guides:
        guide_path = current_dir / guide
        
        if not guide_path.exists():
            print(f"\n✗ {guide} not found")
            continue
        
        pdf_name = guide.replace('.md', '.pdf')
        pdf_path = current_dir / pdf_name
        
        print(f"\nProcessing: {guide}")
        print(f"  -> Output: {pdf_name}")
        
        # Read markdown
        try:
            md_content = read_markdown(str(guide_path))
            print(f"  * Read markdown ({len(md_content)} bytes)")
        except Exception as e:
            print(f"  x Failed to read: {e}")
            continue
        
        # Try different conversion methods
        success = False
        
        # Method 1: HTML + pdfkit
        html_name = guide.replace('.md', '.html')
        html_path = current_dir / html_name
        try:
            html_content = markdown_to_html(md_content)
            with open(html_path, 'w', encoding='utf-8') as f:
                f.write(f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{Path(guide).stem}</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
            background: #f5f5f5;
        }}
        h1, h2, h3, h4 {{
            color: #1f4788;
            margin-top: 20px;
            margin-bottom: 10px;
        }}
        h1 {{ font-size: 24px; }}
        h2 {{ font-size: 20px; border-bottom: 2px solid #1f4788; padding-bottom: 5px; }}
        h3 {{ font-size: 16px; }}
        h4 {{ font-size: 14px; }}
        p {{ text-align: justify; margin: 10px 0; }}
        ul, ol {{ margin: 10px 0; padding-left: 30px; }}
        li {{ margin: 5px 0; }}
        table {{ 
            border-collapse: collapse; 
            width: 100%; 
            margin: 15px 0;
            background: white;
        }}
        th, td {{ 
            border: 1px solid #ddd; 
            padding: 10px; 
            text-align: left;
        }}
        th {{ 
            background-color: #1f4788; 
            color: white; 
            font-weight: bold;
        }}
        tr:nth-child(even) {{ background-color: #f9f9f9; }}
        code {{ 
            background: #f4f4f4; 
            padding: 2px 6px; 
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }}
        blockquote {{
            border-left: 4px solid #1f4788;
            padding-left: 15px;
            margin: 15px 0;
            color: #555;
            background: #f0f0f0;
            padding: 10px 15px;
        }}
        .page-break {{ page-break-after: always; }}
        @page {{ margin: 20mm; }}
    </style>
</head>
<body>
{html_content}
</body>
</html>""")
            print(f"  * Created HTML")
            
            success = create_pdf_from_html(str(html_path), str(pdf_path))
            if success and os.path.exists(pdf_path):
                size_mb = os.path.getsize(pdf_path) / (1024 * 1024)
                print(f"  * Created PDF ({size_mb:.1f} MB)")
                success_count += 1
        except Exception as e:
            print(f"  ! HTML/pdfkit method failed: {e}")
        
        # Method 2: Simple ReportLab conversion
        if not success:
            try:
                if simple_md_to_pdf(str(guide_path), str(pdf_path)):
                    size_mb = os.path.getsize(pdf_path) / (1024 * 1024)
                    print(f"  * Created PDF using ReportLab ({size_mb:.1f} MB)")
                    success_count += 1
                    success = True
                else:
                    print(f"  x ReportLab conversion failed")
            except ImportError:
                print(f"  ! ReportLab not installed, trying text export...")
                # Fallback: create a text file
                try:
                    txt_name = guide.replace('.md', '.txt')
                    with open(current_dir / txt_name, 'w', encoding='utf-8') as f:
                        f.write(md_content)
                    print(f"  * Created text version ({txt_name})")
                except Exception as e:
                    print(f"  x Failed: {e}")
    
    print("\n" + "=" * 60)
    print(f"Conversion Complete: {success_count}/{len(guides)} PDFs created")
    print("=" * 60)

if __name__ == '__main__':
    main()
