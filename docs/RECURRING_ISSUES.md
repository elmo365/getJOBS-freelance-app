# Recurring Issues Tracker

This document tracks recurring issues that have been reported multiple times and their fixes.
When implementing changes, **always check this document first** to ensure proper implementation.

---

## Issue Categories

### 1. Card Rounding Issues
**Status**: ✅ FIXED

**Problem**: Cards (especially profile hero cards and Job Discovery cards) have unwanted rounding at bottom corners.

**Root Cause**: The `AppDesignSystem.heroCard()` function defaulted to `BorderRadius.circular(radiusXL)`.

**Fix Applied**:
- Changed default `borderRadius` in `heroCard()` to `BorderRadius.zero`
- File: `lib/utils/app_design_system.dart`

**Verification**:
- Profile cards (job seeker, company) should have square corners
- Job Discovery hero section should have no rounding

---

### 2. Blue AppBar Not Implemented
**Status**: ✅ FIXED (using AppBarVariant.primary)

**Problem**: Blue AppBar was requested but screens were using standard/white AppBar.

**Solution**:
- Use `AppAppBar` with `variant: AppBarVariant.primary` for blue background
- Colors are centralized in `lib/widgets/common/app_app_bar.dart`

**AppBar Variants Available**:
- `AppBarVariant.standard` - White/light background
- `AppBarVariant.primary` - Blue background (BOTS Blue)
- `AppBarVariant.secondary` - Yellow background (BOTS Yellow)
- `AppBarVariant.tertiary` - Green background (BOTS Green)
- `AppBarVariant.error` - Red background
- `AppBarVariant.surface` - Theme surface color

---

### 3. Keyboard Covering Input Fields
**Status**: ✅ FIXED

**Problem**: On mobile devices, the keyboard covers input fields, especially in forms and search bars.

**Solution Applied**:
- Add `scrollPadding` to TextFields:
```dart
scrollPadding: EdgeInsets.only(
  bottom: MediaQuery.of(context).viewInsets.bottom + 100,
),
```
- Wrap forms in `SingleChildScrollView` with `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`

**Files Fixed**:
- `lib/screens/admin/admin_api_settings_screen.dart`
- `lib/screens/admin/admin_panel_screen.dart`
- `lib/screens/admin/admin_companies_list_screen.dart`
- `lib/screens/job_seekers/cv_builder_screen.dart`

---

### 4. Admin Panel Search Not Working
**Status**: ✅ FIXED

**Problem**: 
- Search input triggers screen reload instead of filtering
- Duplicate search fields (header and body)
- Search query not converted to lowercase for case-insensitive search

**Solution Applied**:
- Removed duplicate search field from body (kept only header search)
- Fixed `onChanged` to convert query to lowercase: `value.toLowerCase()`
- Added proper `scrollPadding` to prevent keyboard issues

**File**: `lib/screens/admin/admin_panel_screen.dart`

---

### 5. CV Builder Using Popups Instead of Inline Forms
**Status**: ✅ FIXED

**Problem**: Education, Experience, Languages, Certifications, and Projects were added via popup dialogs, causing keyboard issues and poor UX.

**Solution Applied**:
- Converted all dialog-based forms to inline expandable forms
- Added state variables: `_showEducationForm`, `_showExperienceForm`, etc.
- Created inline form builders: `_buildInlineEducationForm()`, etc.
- Removed old dialog methods

**File**: `lib/screens/job_seekers/cv_builder_screen.dart`

**Pattern for inline forms**:
1. Toggle visibility with state variable
2. Show form in same container as list
3. Clear form on add or cancel
4. Use `AppCard` for consistent styling

---

### 6. API Settings Screen Issues
**Status**: ✅ FIXED

**Problem**:
- Black/empty background during loading
- Keyboard covering inputs
- UI not matching Hints settings style

**Solution Applied**:
- Loading state now shows proper Scaffold with background color
- Added `scrollPadding` to all TextField inputs
- Applied consistent styling with filled inputs and borders
- Background uses `botsSuperLightGrey`

**File**: `lib/screens/admin/admin_admin_settings_screen.dart`

---

### 7. Job Posting Notifications to Admin
**Status**: ✅ VERIFIED (Already Implemented)

**Problem**: Need to verify admin receives notifications when jobs are posted.

**Implementation Location**: `lib/screens/employers/job_posting_screen.dart`

**Flow**:
1. Employer posts job → notification sent to employer (confirmation)
2. System queries admin users with `isAdmin = true`
3. Sends notification to each admin with type `'job_pending_approval'`

**Code Reference** (lines 520-542):
```dart
// Send notification to admin for all job postings
final admins = await _dbService.getAdminUsers(limit: 100);
for (var adminDoc in admins.docs) {
  await _notificationService.sendNotification(
    userId: adminDoc.id,
    type: 'job_pending_approval',
    title: 'New Job Pending Approval',
    body: '...',
    sendEmail: true,
  );
}
```

---

## Prevention Guidelines

### Before Making UI Changes:
1. Check this document for known patterns
2. Use centralized components (`AppAppBar`, `AppCard`, `AppDesignSystem`)
3. Always add `scrollPadding` to form TextFields
4. Test with keyboard open on mobile

### For New Forms:
1. Use inline forms instead of popups
2. Wrap in `SingleChildScrollView` with `keyboardDismissBehavior`
3. Use consistent styling from `AppDesignSystem`

### For Search Fields:
1. Convert input to lowercase for filtering
2. Use single search source (avoid duplicates)
3. Filter data client-side without triggering reloads

---

## Cross-Reference

Related documentation:
- `docs/UX_ISSUES.md` - Detailed UX issues and fixes
- `docs/COLOR_BALANCE_UPDATE.md` - BOTS brand colors
- `docs/BOTS_COLORS_UPDATE.md` - Color usage guidelines
- `UI_OVERHAUL_PROGRESS.md` - UI modernization progress

---

*Last Updated: December 2024*

