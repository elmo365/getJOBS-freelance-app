## UX / UI Issues Tracker

This file documents the main UX / UI problems identified in the app and tracks their fixes.  
Use the checkboxes to mark items as **Done** when a fix has been implemented and tested.

---

### Legend
- **[ ]** Not started
- **[~]** In progress / partially fixed
- **[x]** Fixed and verified

---

## 1. Hints System (Global)

- **[x] Issue 1.1 – Hints push layout down instead of overlaying**
  - **Screens affected**: Welcome/Login, Job Discovery, Profile, Admin panels, others wrapped in `HintsWrapper`.
  - **Symptoms**:
    - Hint banners appear as large colored blocks at the top.
    - They push the entire UI down, creating extra “blank” space.
    - When the hint is dismissed, the whole layout jumps back up.
  - **Root cause**:
    - `HintsWrapper` currently wraps children in a `Column(HintBanner, Expanded(child))`, so hints occupy layout space instead of acting as overlays.
  - **Fix implemented**:
    - Updated `lib/widgets/common/hints_wrapper.dart` to render hints as a non-intrusive overlay:
      - Wraps `widget.child` and `HintBanner` in a `Stack`.
      - Uses `Align + SafeArea` to position the hint at the top without pushing layout down.
    - Business logic (which hints load, AI hints, enable/disable) remains unchanged.

---

## 2. Job Discovery Screen (Search / Results)

File: `lib/screens/search/search_screen.dart`

- **[x] Issue 2.1 – Jobs feel squeezed at the bottom when there are few results**
  - **Screenshots**: Job Discovery with 1 job card shown in a small area at the bottom.
  - **Symptoms (before)**:
    - Large hero section (“Find Your Perfect Job”) + filters took most vertical space.
    - With only 1 job, the results card felt cramped and visually disconnected near the bottom of the screen.
  - **Code-level root cause (before)**:
    - The `body` used a `Column` containing:
      - A tall hero (`AppDesignSystem.heroCard`) with generous vertical padding.
      - A padded filters `Column`.
      - An `Expanded` at the bottom hosting the results list.
    - This stacked layout reduced the visible height of the results area, especially on smaller devices.
  - **Fix implemented**:
    - Refactored the body to use a single `CustomScrollView`:
      - Hero, filters, results header, and the job list are now separate slivers within one scroll container.
      - The job list is rendered directly in the main scroll as a list of `ModernJobCard`s, so results always use the remaining screen height and scroll with the device.
    - Hero and filter padding remain visually balanced but no longer cause the results to appear trapped in a small “box” at the bottom of the screen.

- **[x] Issue 2.2 – No clear “browse all jobs” mode (list without search)**
  - **Symptoms (before)**:
    - From the user’s perspective, it was not obvious that they could simply “see all jobs” without entering search text.
    - Search UI dominated, giving the impression that searching was mandatory instead of optional refinement.
  - **Implementation details (after)**:
    - `_buildJobsQuery()` in `search_screen.dart` already treated empty keyword/location as “no constraint”, returning all active jobs ordered by newest first.
    - With the new `CustomScrollView` layout and the pagination limit (see Issue 2.3), opening Job Discovery with empty fields now clearly shows a **browse-all jobs** list by default, with filters and search acting as refinements.
    - The “Filters” section and AI search remain visible but do not block seeing the job list.

- **[x] Issue 2.3 – No pagination / load-more pattern for many jobs**
  - **Risk (before)**: When there were many jobs (e.g., 100+), the screen streamed and rendered the entire list at once.
  - **Code-level root cause (before)**:
    - The jobs `StreamBuilder` in `search_screen.dart` called `_buildJobsQuery().snapshots()` with no `limit`, and the UI rendered all returned documents in a single list.
  - **Fix implemented**:
    - Added simple Firestore pagination using `limit(_currentLimit)` where `_currentLimit` begins at `_pageSize` (20) and grows in increments of 20.
    - When the snapshot size reaches the current limit, a **“Load more jobs”** `OutlinedButton` appears under the list; tapping it increases `_currentLimit` and triggers a rebuild, streaming in the next batch.
    - Changing category, experience, sort, clearing filters, or applying AI smart search now resets `_currentLimit` back to the first page to avoid overly large queries.

---

## 2b. Global “Boxed” Content / Nested Scroll Areas

- **[~] Issue 2b.1 – Content constrained inside small “display boxes” instead of full-screen scrolling**
  - **Screens affected (examples)**:
    - Job Discovery results area.
    - Some cards/sections where a `Container` + internal scrollable is used inside another scrollable layout.
  - **Symptoms**:
    - On small devices, lists (jobs, cards, forms) appear inside a small box with their own scroll, while the rest of the screen is static.
    - Users feel like content is “cut off” or only shown in a tiny region, instead of using the full device height.
  - **Desired behavior**:
    - Primary content (job lists, main forms, etc.) should scroll **with the device screen**, not inside nested scroll boxes.
    - Avoid nested scrolling where possible; prefer a single top-level `ListView` / `CustomScrollView` / `SingleChildScrollView` per screen.
  - **Current status**:
    - **Job Discovery** has been refactored (see Issue 2.1) to use a single `CustomScrollView` with the job list rendered inline as part of the main scroll—not inside a separate scroll box.
    - Admin/company review screens and most dashboard lists use either a single primary scrollable or inner lists with `NeverScrollableScrollPhysics` + `shrinkWrap`, meaning the device scroll controls the whole page rather than a tiny inner region.
    - Some builder-style screens (e.g. CV Builder education/experience lists) still use `Flexible + ListView.builder` patterns but do **not** create a second scrollable viewport; they rely on the parent layout for scrolling and are kept for now to avoid breaking complex multi-step flows.
  - **Next steps**:
    - Continue to avoid adding new nested scrollables for primary content; prefer a single `ListView` / `CustomScrollView` per screen.
    - When revisiting CV and admin tooling UIs, consider replacing `Flexible + ListView.builder` patterns with simple `Column` + `List.generate` where the expected item count is small, to further simplify layouts without risking overflow on long lists.

---

## 3. Profile Screens (Job Seeker, Company, Admin)

Files: 
- Job Seeker profile: `lib/screens/profile/profile.dart`
- Company profile: `lib/screens/profile/profile_company.dart`
- Any future/admin profile views that reuse the same top-bar + hero patterns

- **[x] Issue 3.1 – Unnecessary search bar in profile header**
  - **Symptoms**:
    - Profile header row shows: menu + search field (e.g. “Search profile…”, “Search company profile…”) + notifications/edit.
    - Search does not add clear value on a single-user profile screen and clutters the header.
  - **Code-level root cause**:
    - In `profile.dart`, the top bar `Row` always includes a `ModernSearchBar` with `hintText: 'Search profile...'` even though no actual search behavior is wired for profile-specific data.
    - In `profile_company.dart`, the top bar similarly includes a `ModernSearchBar` with `hintText: 'Search company profile...'` that navigates to the general search screen, duplicating search entry points and cluttering the profile header.
    - This pattern was likely copied from dashboard layouts where search makes more sense and then reused across profile screens for different roles (job seeker, company, admin).
  - **Fix implemented**:
    - `profile.dart` (job seeker profile):
      - Removed `ModernSearchBar` from the header.
      - Kept a simple header: menu button, notifications icon with unread badge (using existing `_getUnreadCount()`), and edit icon for own profile.
    - `profile_company.dart` (company profile):
      - Removed `ModernSearchBar` that navigated to general search.
      - Kept a clean header with menu button (and room for future actions).
    - No changes to profile data loading, navigation, or business logic—only header layout.

- **[ ] Issue 3.2 – Gradient hero/header shape clashes with app bar**
  - **Symptoms**:
    - Hero card/gradient under the app bar has rounded top corners/arc that does not visually align with the straight app bar.
    - Creates a “card under bar” effect rather than a unified header.
  - **Code-level root cause**:
    - The profile uses `AppDesignSystem.heroCard` inside the scrollable body, beneath a separate `Scaffold` app bar, so the hero is rendered as a **card** with its own border radius instead of as part of the app bar background.
    - There is no `SliverAppBar` / `Stack` tying the hero background to the app bar’s background color/gradient.
  - **Planned fixes** (one of):
    - Extend hero gradient behind the app bar (using `Stack` or `SliverAppBar`‑style layout) so there is a single continuous header.
    - Or, square off the top corners of the hero card on the profile screen so it aligns better with the app bar.

---

## 4. Onboarding / Introduction Screen

File: `lib/screens/introduction_screen.dart`

- **[x] Issue 4.1 – Content overlaps with phone status bar**
  - **Screenshots**: Last intro page (“Build Your Career”) shows title overlapping status icons.
  - **Root cause**:
    - Previously, `IntroductionScreen` was rendered directly under the animated background without a `SafeArea`, allowing content to extend under the status bar on some devices.
  - **Fix implemented**:
    - Wrapped `IntroductionScreen` in `SafeArea` in `lib/screens/introduction_screen.dart` so all pages respect the system status bar and bottom insets.
    - Kept existing page decorations and content; only the safe insets behavior changed.

---

## 5. Job Cards / Listing Layout

- **[ ] Issue 5.1 – Job list density and card presentation**
  - **Observation**:
    - Job cards look good individually, but on small screens the combination of large paddings and hero/banner sections can make the first card appear “far” from the search area.
  - **Planned tweaks**:
    - Slightly reduce vertical padding between hero, filters, and first result.
    - Confirm that `ModernJobCard` expands to full available width and uses sensible internal padding.

---

## 6. Hints Content & Density

- **[ ] Issue 6.1 – Some hints are too verbose for banner format**
  - **Example**: Initial “Get Started” hint on the welcome screen has long instructional text and visually dominates the screen.
  - **Planned fix**:
    - Shorten banner text to a concise 1–2 line tip.
    - Move detailed onboarding instructions into a help / user manual / FAQ page, linked from the banner or profile/settings.

---

## 7. Text Overflow & Typography

- **[x] Issue 7.1 – Step labels wrapping awkwardly in CV Builder**
  - **Before**: Labels like “Education”, “Experience”, “Skills & Summary” could wrap into odd line breaks on small screens (e.g., “Educati\non”).
  - **Fix implemented**:
    - Updated `_buildModernStepIndicator` in `cv_builder_screen.dart`:
      - Added `maxLines: 1` and `overflow: TextOverflow.ellipsis` on the label `Text`.

- **[ ] Issue 7.2 – Other long labels / titles on small screens**
  - **Next actions**:
    - Audit primary headings and chip labels (e.g., hero titles, long button texts) and apply `maxLines` + `overflow` where appropriate.

---

## 8. Keyboard & Input Behavior (Global)

- **[x] Issue 8.1 – Keyboard covering input fields**
  - **Symptoms (before)**:
    - On CV Builder and other forms, when the keyboard opened, some fields and buttons (especially inside dialogs) were obscured.
  - **Fixes implemented (shared widgets)**:
    - `lib/widgets/common/app_text_field.dart`:
      - Added keyboard-aware `scrollPadding`:
        ```dart
        scrollPadding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 80,
        ),
        ```
    - `lib/widgets/common/standard_input.dart`:
      - Similar `scrollPadding` using `AppTheme.spacingXL`.
  - **Fixes implemented (CV Builder specific)**:
    - `_buildModernTextField` in `cv_builder_screen.dart`:
      - Added `scrollPadding` using `MediaQuery.of(context).viewInsets.bottom`.
    - All CV Builder dialogs (`Add Education`, `Add Experience`, `Add Language`, `Add Certification`, `Add Project`, `CV Preview`):
      - `AlertDialog` now uses:
        - `scrollable: true`
        - `insetPadding` with bottom padding based on `viewInsets.bottom`.

---

## 9. Open Questions / To‑Confirm

- **[ ] Q9.1** – After hint overlay refactor, verify:
  - Welcome/Login, Job Discovery, Profile, Admin panels: hints appear as overlays and do not shift primary layout.
- **[ ] Q9.2** – Job Discovery with many jobs:
  - Confirm scroll performance and whether pagination is needed immediately.
- **[ ] Q9.3** – Profile header on different roles:
  - Ensure simplification works for Job Seeker, Employer, and Admin profiles without losing needed actions.

---

> When a fix is implemented, update the corresponding checkbox to `[x]` and, if helpful, add a short note (file name + line range) under the item.


