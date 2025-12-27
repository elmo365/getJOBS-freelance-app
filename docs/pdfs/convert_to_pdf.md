# Converting HTML to PDF

All manuals have been converted to HTML format. To convert them to PDF:

## Method 1: Browser Print (Easiest & Recommended)

1. **Open the HTML file** in your browser (Chrome, Edge, Firefox)
2. **Press `Ctrl + P`** (or right-click → Print)
3. **Select "Save as PDF"** as the destination
4. **Click "Save"**
5. Done! ✅

**Tips:**
- Use Chrome or Edge for best results
- Enable "Background graphics" for better formatting
- Set margins to "Default" or "Minimum"
- Check "Headers and footers" if you want page numbers

## Method 2: Using PowerShell Script

Run this command to open all HTML files in your default browser:

```powershell
cd C:\Users\Diane\OneDrive\Documents\GitHub\getJOBS-freelance-app\docs\pdfs
Get-ChildItem *.html | ForEach-Object { Start-Process $_.FullName }
```

Then print each one to PDF using `Ctrl + P`.

## Generated Files

✅ **USER_MANUAL.html** - Job Seeker Manual  
✅ **COMPANY_MANUAL.html** - Company & Employer Manual  
✅ **ADMIN_USER_MANUAL.html** - Administrator User Manual  
✅ **ADMIN_GUIDE.html** - Technical Admin Reference  
✅ **AI_ROADMAP.html** - AI Features Roadmap  

## File Locations

All HTML files are in: `docs/pdfs/`

---

*Last Updated: December 2024*

