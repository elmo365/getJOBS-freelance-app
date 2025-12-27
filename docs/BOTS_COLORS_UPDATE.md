# BOTSJOBSCONNECT Brand Colors Implementation

## Overview
Updated the entire app to use **BOTSJOBSCONNECT brand colors** (botsYellow, botsGreen, botsBlue) while maintaining Frame-1.webp UI patterns (layout, shadows, icon styles).

## Key Principle
- **Frame-1.webp**: Reference for UI style, layout patterns, shadows, icon styles
- **BOTSJOBSCONNECT Colors**: Use brand colors (botsYellow, botsGreen, botsBlue) and their combinations/gradients

## Color Mapping

### Before (Frame-1.webp colors):
- `heroBlue` = `botsVividBlue` (0xFF2563EB) ❌
- `deepBlue` = `botsDeepBlue` (0xFF1E40AF) ❌
- `accentPurple` = `botsAccentPurple` (0xFF7C3AED) ❌
- `accentOrange` = `botsAccentOrange` (0xFFF97316) ❌
- `accentTeal` = `botsAccentTeal` (0xFF0D9488) ❌

### After (BOTSJOBSCONNECT brand colors):
- `heroPrimary` = `botsGreen` (0xFF0F6850) ✅
- `heroSecondary` = `botsBlue` (0xFF4461AD) ✅
- `heroAccent` = `botsYellow` (0xFFEFC018) ✅
- `accent1` = `botsGreen` ✅
- `accent2` = `botsBlue` ✅
- `accent3` = `botsYellow` ✅

## Design System Updates

### `AppDesignSystem` Changes:
1. **heroCard**: Now uses BOTS Green → Blue gradient (instead of vivid blue)
2. **vividCategoryCard**: Uses BOTS brand colors (Green, Blue, Yellow)
3. **Primary gradients**: Use BOTS Green and Blue combinations
4. **Shadows**: Use BOTS colors for colored shadows

## Screen Updates

### ✅ Updated Screens:
1. **Introduction Screen**
   - Gradient: BOTS Green → Blue (Frame-1 style)

2. **Welcome Screen**
   - Background: BOTS Green tint
   - Title: BOTS Green
   - Login button: BOTS Green → Blue gradient
   - Register button: BOTS Green border

3. **Login Screen**
   - Background: BOTS Green tint
   - Logo icon: BOTS Green
   - Title: BOTS Green
   - Input focus: BOTS Green
   - Login button: BOTS Green → Blue gradient

4. **Search Screen**
   - Hero section: BOTS Green → Blue gradient
   - Bookmark icon: BOTS Green

5. **Profile Screen**
   - Hero header: BOTS Green → Blue gradient (Frame-1 style)

6. **CV Builder Screen**
   - Progress header: BOTS Green → Blue gradient

7. **Extra Modules Hub**
   - Hustle Space: BOTS Yellow
   - Tenders Portal: BOTS Blue
   - Youth Opportunities: BOTS Blue
   - News Corner: BOTS Green

8. **Sidebar**
   - Header background: BOTS Green

## BOTSJOBSCONNECT Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **botsYellow** | #EFC018 | Primary brand, warm accents |
| **botsGreen** | #0F6850 | Secondary brand, hero cards |
| **botsBlue** | #4461AD | Accent brand, gradients |

## Gradient Combinations

### Primary Hero Gradient:
```dart
LinearGradient(
  colors: [botsGreen, botsBlue], // Green → Blue
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

### Category Card Colors:
- **Hustle Space**: botsYellow (warm, energetic)
- **Tenders Portal**: botsBlue (professional)
- **Youth Opportunities**: botsBlue (trustworthy)
- **News Corner**: botsGreen (fresh, growth)

## Frame-1.webp Patterns Maintained

✅ **UI Patterns** (from Frame-1.webp):
- Hero card style with gradients
- Vivid category cards with colored shadows
- Circular icons with colored backgrounds
- Soft, natural shadows (`coloredShadow`, `cardShadow`)
- Minimalistic backgrounds
- White text on colored backgrounds
- Semi-transparent overlays

✅ **Layout & Spacing**:
- Consistent spacing system
- Modern typography scale
- Responsive grid layouts
- Card elevation patterns

## Verification

All screens now use:
- ✅ BOTSJOBSCONNECT brand colors (botsYellow, botsGreen, botsBlue)
- ✅ Frame-1.webp UI patterns (layout, shadows, icon styles)
- ✅ Consistent design system
- ✅ No Frame-1.webp colors (vividBlue, deepBlue, accentPurple/Orange/Teal)

---

*Updated: December 2024*
*Design System: Frame-1.webp UI patterns + BOTSJOBSCONNECT brand colors*

