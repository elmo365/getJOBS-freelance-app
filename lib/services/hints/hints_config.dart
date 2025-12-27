import 'package:freelance_app/models/hint_model.dart';

/// Configuration for hints across all screens (50+ screens)
/// Hints are organized by screen ID and are role-aware
class HintsConfig {
  /// Get hints for a specific screen
  static List<HintModel> getHintsForScreen(
    String screenId, {
    required bool monetizationEnabled,
  }) {
    final allHints = _getAllHints(monetizationEnabled: monetizationEnabled);
    return allHints.where((hint) => hint.screenId == screenId).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  static List<HintModel> _getAllHints({required bool monetizationEnabled}) {
    final hints = <HintModel>[];

    // ============================================
    // JOB SEEKER SCREENS
    // ============================================

    // Job Seeker Home Screen
    hints.addAll([
      HintModel(
        id: 'job_seeker_home_ai_matching',
        screenId: 'job_seekers_home',
        title: 'AI Job Matching',
        message:
            'Tap "Smart Job Matching" to get AI-powered job recommendations based on your CV and skills.',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'job_seeker_home_wallet',
        screenId: 'job_seekers_home',
        title: 'Your Wallet',
        message: monetizationEnabled
            ? 'Manage your earnings and payments. Deposit funds to access premium features.'
            : 'Wallet features are currently disabled.',
        type: monetizationEnabled ? HintType.monetization : HintType.info,
        requiresMonetization: true,
        priority: monetizationEnabled ? 4 : 1,
      ),
      HintModel(
        id: 'job_seeker_home_tools',
        screenId: 'job_seekers_home',
        title: 'Career Tools',
        message:
            'Explore tools like CV Builder, Interview Coach, and Career Roadmap to enhance your job search.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // CV Builder Screen
    hints.addAll([
      HintModel(
        id: 'cv_builder_validation',
        screenId: 'cv_builder',
        title: 'Complete Each Step',
        message:
            'Make sure to fill in all required fields before moving to the next step. Your CV will be more complete!',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'cv_builder_education',
        screenId: 'cv_builder',
        title: 'Flexible Education',
        message:
            'You can add both formal and non-formal education. Include online courses, workshops, and certifications!',
        type: HintType.tip,
        priority: 3,
      ),
      HintModel(
        id: 'cv_builder_skills',
        screenId: 'cv_builder',
        title: 'Add Relevant Skills',
        message:
            'List all your skills, including soft skills. This helps AI match you with better job opportunities.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Job Matching Screen
    hints.addAll([
      HintModel(
        id: 'job_matching_cv',
        screenId: 'job_matching',
        title: 'Complete Your CV',
        message:
            'Make sure your CV is up to date for better AI matching results. The more complete your profile, the better the matches!',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'job_matching_refresh',
        screenId: 'job_matching',
        title: 'Refresh Matches',
        message:
            'Pull down to refresh and get new job matches as new opportunities are posted.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Interview Coach Screen
    hints.addAll([
      HintModel(
        id: 'interview_coach_practice',
        screenId: 'interview_coach',
        title: 'Practice Makes Perfect',
        message:
            'Use AI-powered interview questions to practice. Get personalized feedback on your answers!',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'interview_coach_tips',
        screenId: 'interview_coach',
        title: 'Get AI Feedback',
        message:
            'After answering questions, review the AI feedback to improve your interview skills.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Career Roadmap Screen
    hints.addAll([
      HintModel(
        id: 'career_roadmap_ai',
        screenId: 'career_roadmap',
        title: 'AI-Powered Roadmap',
        message:
            'Get a personalized career roadmap based on your goals and current skills. Update your goals to refine the roadmap.',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'career_roadmap_update',
        screenId: 'career_roadmap',
        title: 'Keep It Updated',
        message:
            'Regularly update your career goals to get the most relevant roadmap suggestions.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Career Tracker Screen
    hints.addAll([
      HintModel(
        id: 'career_tracker_progress',
        screenId: 'career_tracker',
        title: 'Track Your Progress',
        message:
            'Monitor your job applications, interviews, and career milestones all in one place.',
        type: HintType.feature,
        priority: 4,
      ),
      HintModel(
        id: 'career_tracker_insights',
        screenId: 'career_tracker',
        title: 'View Insights',
        message:
            'Check your application success rate and identify areas for improvement.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Video Resume Screen
    hints.addAll([
      HintModel(
        id: 'video_resume_tips',
        screenId: 'video_resume',
        title: 'Create a Standout Video',
        message:
            'Record a professional video resume to showcase your personality and communication skills to employers.',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'video_resume_duration',
        screenId: 'video_resume',
        title: 'Keep It Concise',
        message:
            'Aim for 1-2 minutes. Highlight your key skills and achievements.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Application History Screen
    hints.addAll([
      HintModel(
        id: 'application_history_track',
        screenId: 'application_history',
        title: 'Track All Applications',
        message:
            'View all your job applications, their status, and follow up on pending applications.',
        type: HintType.info,
        priority: 4,
      ),
      HintModel(
        id: 'application_history_status',
        screenId: 'application_history',
        title: 'Check Status',
        message:
            'Regularly check the status of your applications and follow up when needed.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Mentorship Corner Screen
    hints.addAll([
      HintModel(
        id: 'mentorship_find',
        screenId: 'mentorship_corner',
        title: 'Find a Mentor',
        message:
            'Connect with experienced professionals who can guide your career journey.',
        type: HintType.feature,
        priority: 4,
      ),
      HintModel(
        id: 'mentorship_benefits',
        screenId: 'mentorship_corner',
        title: 'Benefits of Mentorship',
        message:
            'Get career advice, industry insights, and personalized guidance from mentors.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // ============================================
    // EMPLOYER SCREENS
    // ============================================

    // Employers Home Screen
    hints.addAll([
      HintModel(
        id: 'employer_home_post',
        screenId: 'employers_home',
        title: 'Post a Job',
        message:
            'Click "Post a Job" to create a new job listing. Fill in all details for better candidate matches.',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'employer_home_applicants',
        screenId: 'employers_home',
        title: 'Review Applicants',
        message:
            'Check the Applications section to review candidates who applied to your jobs.',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'employer_home_ai',
        screenId: 'employers_home',
        title: 'AI Candidate Suggestions',
        message:
            'Use AI-powered candidate suggestions to find the best matches for your job postings.',
        type: HintType.feature,
        priority: 4,
      ),
    ]);

    // Job Posting Screen
    hints.addAll([
      HintModel(
        id: 'job_posting_details',
        screenId: 'job_posting',
        title: 'Detailed Job Descriptions',
        message:
            'Provide clear, detailed job descriptions. This helps attract the right candidates and improves AI matching.',
        type: HintType.tip,
        priority: 5,
      ),
      HintModel(
        id: 'job_posting_requirements',
        screenId: 'job_posting',
        title: 'List Requirements',
        message:
            'Clearly list required skills, experience level, and qualifications to filter candidates effectively.',
        type: HintType.tip,
        priority: 4,
      ),
      if (monetizationEnabled)
        HintModel(
          id: 'job_posting_payment',
          screenId: 'job_posting',
          title: 'Payment Required',
          message:
              'Job postings require payment. Ensure your wallet has sufficient funds.',
          type: HintType.monetization,
          requiresMonetization: true,
          priority: 3,
        ),
    ]);

    // Application Review Screen
    hints.addAll([
      HintModel(
        id: 'application_review_ai',
        screenId: 'application_review',
        title: 'AI-Powered Review',
        message:
            'Use AI insights to quickly identify top candidates based on CV analysis and job requirements.',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'application_review_contact',
        screenId: 'application_review',
        title: 'Quick Contact',
        message:
            'Use the contact buttons to quickly reach out to candidates via email, phone, or WhatsApp.',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'application_review_cv',
        screenId: 'application_review',
        title: 'View Full CV',
        message:
            'Click on a candidate to view their complete CV and make informed hiring decisions.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Candidate Suggestions Screen
    hints.addAll([
      HintModel(
        id: 'candidate_suggestions_ai',
        screenId: 'candidate_suggestions',
        title: 'AI Candidate Matching',
        message:
            'Get AI-powered candidate suggestions based on your job requirements. Review and contact top matches.',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'candidate_suggestions_refresh',
        screenId: 'candidate_suggestions',
        title: 'Refresh Suggestions',
        message:
            'Pull down to refresh and get new candidate suggestions as new profiles are added.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Company Verification Screen
    hints.addAll([
      HintModel(
        id: 'company_verification_required',
        screenId: 'company_verification',
        title: 'Verification Required',
        message:
            'Complete company verification to unlock all features and build trust with job seekers.',
        type: HintType.warning,
        priority: 5,
      ),
      HintModel(
        id: 'company_verification_documents',
        screenId: 'company_verification',
        title: 'Upload Documents',
        message:
            'Upload required business documents for faster verification approval.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Interview Scheduling Screen
    hints.addAll([
      HintModel(
        id: 'interview_scheduling_calendar',
        screenId: 'interview_scheduling',
        title: 'Schedule Interviews',
        message:
            'Use the calendar to schedule interviews with candidates. Send automatic reminders.',
        type: HintType.feature,
        priority: 4,
      ),
      HintModel(
        id: 'interview_scheduling_reminders',
        screenId: 'interview_scheduling',
        title: 'Automatic Reminders',
        message:
            'Candidates will receive automatic reminders for scheduled interviews.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // ============================================
    // TRAINER SCREENS
    // ============================================

    // Trainers Home Screen
    hints.addAll([
      HintModel(
        id: 'trainer_home_create',
        screenId: 'trainers_home',
        title: 'Create a Course',
        message:
            'Create and publish courses to share your expertise with job seekers and professionals.',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'trainer_home_sessions',
        screenId: 'trainers_home',
        title: 'Live Sessions',
        message:
            'Schedule and conduct live training sessions for interactive learning experiences.',
        type: HintType.feature,
        priority: 4,
      ),
      HintModel(
        id: 'trainer_home_analytics',
        screenId: 'trainers_home',
        title: 'View Analytics',
        message:
            'Track course enrollments, completion rates, and student feedback.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Courses Screen
    hints.addAll([
      HintModel(
        id: 'courses_create',
        screenId: 'courses',
        title: 'Create Engaging Courses',
        message:
            'Create comprehensive courses with videos, materials, and assessments to help learners succeed.',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'courses_publish',
        screenId: 'courses',
        title: 'Publish Your Courses',
        message:
            'Once your course is ready, publish it to make it available to all learners.',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'courses_manage',
        screenId: 'courses',
        title: 'Manage Courses',
        message:
            'Edit, update, or unpublish courses as needed. Track student progress and engagement.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Live Sessions Screen
    hints.addAll([
      HintModel(
        id: 'live_sessions_schedule',
        screenId: 'live_sessions',
        title: 'Schedule Sessions',
        message:
            'Schedule live training sessions and invite learners. Set up recurring sessions for regular training.',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'live_sessions_interactive',
        screenId: 'live_sessions',
        title: 'Interactive Learning',
        message:
            'Use live sessions for interactive Q&A, demonstrations, and real-time feedback.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // ============================================
    // ADMIN SCREENS
    // ============================================

    // Admin Panel Screen
    hints.addAll([
      HintModel(
        id: 'admin_api_keys',
        screenId: 'admin_panel',
        title: 'API Configuration',
        message:
            'Configure AI and email service API keys in the API Settings tab to enable all features.',
        type: HintType.warning,
        priority: 5,
      ),
      HintModel(
        id: 'admin_monetization',
        screenId: 'admin_panel',
        title: 'Monetization Control',
        message:
            'Control monetization visibility for job seekers and companies in the Monetization tab.',
        type: HintType.info,
        priority: 4,
      ),
      HintModel(
        id: 'admin_approvals',
        screenId: 'admin_panel',
        title: 'Review Pending Items',
        message:
            'Check the Pending tab to review and approve company verifications and job postings.',
        type: HintType.warning,
        priority: 4,
      ),
    ]);

    // Admin API Settings Screen
    hints.addAll([
      HintModel(
        id: 'admin_api_configure',
        screenId: 'admin_api_settings',
        title: 'Configure API Keys',
        message:
            'Set up Gemini AI and Brevo email API keys. These are required for AI features and email notifications.',
        type: HintType.warning,
        priority: 5,
      ),
      HintModel(
        id: 'admin_api_security',
        screenId: 'admin_api_settings',
        title: 'Keep Keys Secure',
        message:
            'API keys are securely stored. Never share them publicly. Toggle visibility to view or hide keys.',
        type: HintType.warning,
        priority: 3,
      ),
    ]);

    // Admin Finance Screen
    hints.addAll([
      HintModel(
        id: 'admin_finance_monitor',
        screenId: 'admin_finance',
        title: 'Monitor Finances',
        message:
            'Track all financial transactions, top-up requests, and manage monetization settings.',
        type: HintType.info,
        priority: 5,
      ),
      if (monetizationEnabled)
        HintModel(
          id: 'admin_finance_topups',
          screenId: 'admin_finance',
          title: 'Review Top-Up Requests',
          message:
              'Review and approve user top-up requests to add funds to their wallets.',
          type: HintType.monetization,
          requiresMonetization: true,
          priority: 4,
        ),
    ]);

    // Admin Approval Screen
    hints.addAll([
      HintModel(
        id: 'admin_approval_review',
        screenId: 'admin_approval',
        title: 'Review Applications',
        message:
            'Review company verification requests and job postings. Approve or reject with feedback.',
        type: HintType.warning,
        priority: 5,
      ),
      HintModel(
        id: 'admin_approval_ai',
        screenId: 'admin_approval',
        title: 'AI Matching',
        message:
            'Use AI to match approved jobs with suitable candidates and send notifications.',
        type: HintType.feature,
        priority: 3,
      ),
    ]);

    // ============================================
    // PLUGIN SCREENS
    // ============================================

    // Plugins Hub
    hints.addAll([
      HintModel(
        id: 'plugins_discover',
        screenId: 'plugins_hub',
        title: 'Explore Features',
        message:
            'Discover additional features like Gig Space, Courses, Tenders, and more. Each plugin offers unique opportunities!',
        type: HintType.feature,
        priority: 4,
      ),
    ]);

    // Gig Space Screen
    hints.addAll([
      HintModel(
        id: 'gig_space_post',
        screenId: 'gig_space',
        title: 'Post a Gig',
        message:
            'Post freelance gigs or find gig opportunities. Set your rates and showcase your skills.',
        type: HintType.feature,
        priority: 4,
      ),
      HintModel(
        id: 'gig_space_browse',
        screenId: 'gig_space',
        title: 'Browse Gigs',
        message:
            'Browse available gigs and apply to ones that match your skills and interests.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Tenders Portal Screen
    hints.addAll([
      HintModel(
        id: 'tenders_post',
        screenId: 'tenders_portal',
        title: 'Post Tenders',
        message:
            'Companies can post tenders for projects. Job seekers and companies can apply.',
        type: HintType.feature,
        priority: 4,
      ),
      HintModel(
        id: 'tenders_apply',
        screenId: 'tenders_portal',
        title: 'Apply to Tenders',
        message:
            'Browse and apply to tenders that match your capabilities. Companies cannot apply to their own tenders.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Blue Pages Screen
    hints.addAll([
      HintModel(
        id: 'blue_pages_business',
        screenId: 'blue_pages',
        title: 'Add Your Business',
        message:
            'Companies can add their business listing to Blue Pages for better visibility.',
        type: HintType.feature,
        priority: 4,
      ),
      HintModel(
        id: 'blue_pages_discover',
        screenId: 'blue_pages',
        title: 'Discover Businesses',
        message:
            'Browse verified businesses and connect with companies in your industry.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Youth Opportunities Screen
    hints.addAll([
      HintModel(
        id: 'youth_opportunities_browse',
        screenId: 'youth_opportunities',
        title: 'Youth Opportunities',
        message:
            'Browse opportunities specifically for youth, including internships, scholarships, and training programs.',
        type: HintType.feature,
        priority: 4,
      ),
      HintModel(
        id: 'youth_opportunities_apply',
        screenId: 'youth_opportunities',
        title: 'Apply Early',
        message:
            'Apply early to increase your chances. Check deadlines and requirements carefully.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // News Corner Screen
    hints.addAll([
      HintModel(
        id: 'news_corner_stay_updated',
        screenId: 'news_corner',
        title: 'Stay Updated',
        message:
            'Read the latest news, industry updates, and career tips to stay informed.',
        type: HintType.info,
        priority: 3,
      ),
      HintModel(
        id: 'news_corner_categories',
        screenId: 'news_corner',
        title: 'Filter by Category',
        message:
            'Use categories to find news relevant to your interests and career field.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Hustle Space Screen
    hints.addAll([
      HintModel(
        id: 'hustle_space_quick',
        screenId: 'hustle_space',
        title: 'Quick Opportunities',
        message:
            'Find quick freelance opportunities and side hustles to earn extra income.',
        type: HintType.feature,
        priority: 4,
      ),
      HintModel(
        id: 'hustle_space_apply',
        screenId: 'hustle_space',
        title: 'Fast Applications',
        message:
            'Apply quickly to hustle opportunities. These are typically short-term projects.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // ============================================
    // COMMON SCREENS
    // ============================================

    // Search Screen
    hints.addAll([
      HintModel(
        id: 'search_ai_smart',
        screenId: 'search',
        title: 'AI Smart Search',
        message:
            'Tap the ✨ button to use AI-powered search. Just describe what you\'re looking for in natural language!',
        type: HintType.feature,
        priority: 5,
      ),
      HintModel(
        id: 'search_save',
        screenId: 'search',
        title: 'Save Your Searches',
        message:
            'Tap the bookmark icon to save your search criteria and access it later.',
        type: HintType.tip,
        priority: 3,
      ),
      HintModel(
        id: 'search_filters',
        screenId: 'search',
        title: 'Use Filters',
        message:
            'Refine your search by category, experience level, and location to find the perfect match.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Chat Screen
    hints.addAll([
      HintModel(
        id: 'chat_notifications',
        screenId: 'chat',
        title: 'Stay Connected',
        message:
            'You\'ll receive notifications for new messages. Tap notifications to go directly to the conversation.',
        type: HintType.info,
        priority: 3,
      ),
      HintModel(
        id: 'chat_quick',
        screenId: 'chat',
        title: 'Quick Communication',
        message:
            'Communicate directly with employers or candidates through in-app messaging.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Chat List Screen
    hints.addAll([
      HintModel(
        id: 'chat_list_unread',
        screenId: 'chat_list',
        title: 'Unread Messages',
        message:
            'Messages with unread indicators need your attention. Tap to open and respond.',
        type: HintType.info,
        priority: 3,
      ),
      HintModel(
        id: 'chat_list_start',
        screenId: 'chat_list',
        title: 'Start Conversations',
        message:
            'Start new conversations from job applications or candidate profiles.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Wallet Screen
    if (monetizationEnabled) {
      hints.addAll([
        HintModel(
          id: 'wallet_deposit',
          screenId: 'wallet',
          title: 'Deposit Funds',
          message:
              'Add funds to your wallet to access premium features and make payments for job postings.',
          type: HintType.monetization,
          requiresMonetization: true,
          priority: 4,
        ),
        HintModel(
          id: 'wallet_history',
          screenId: 'wallet',
          title: 'Transaction History',
          message:
              'View all your deposits and transactions in the history section.',
          type: HintType.monetization,
          requiresMonetization: true,
          priority: 2,
        ),
      ]);
    }

    // Profile Screen
    hints.addAll([
      HintModel(
        id: 'profile_complete',
        screenId: 'profile',
        title: 'Complete Your Profile',
        message:
            'A complete profile increases your visibility. Add a photo, bio, and all relevant information.',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'profile_settings',
        screenId: 'profile',
        title: 'Manage Settings',
        message:
            'Update your profile, change password, and manage notification preferences.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Edit Profile Screen
    hints.addAll([
      HintModel(
        id: 'edit_profile_update',
        screenId: 'edit_profile',
        title: 'Keep Profile Updated',
        message:
            'Regularly update your profile with new skills, experiences, and achievements.',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'edit_profile_photo',
        screenId: 'edit_profile',
        title: 'Add a Professional Photo',
        message:
            'A professional photo increases your profile views and makes a great first impression.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Notifications Screen
    hints.addAll([
      HintModel(
        id: 'notifications_manage',
        screenId: 'notifications',
        title: 'Manage Notifications',
        message:
            'View all your notifications. Tap to open related content or mark as read.',
        type: HintType.info,
        priority: 3,
      ),
      HintModel(
        id: 'notifications_settings',
        screenId: 'notifications',
        title: 'Notification Settings',
        message: 'Customize notification preferences in your profile settings.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Activity Screen
    hints.addAll([
      HintModel(
        id: 'activity_track',
        screenId: 'activity',
        title: 'Track Your Activity',
        message:
            'View all your job applications, posted jobs, and activity history in one place.',
        type: HintType.info,
        priority: 3,
      ),
      HintModel(
        id: 'activity_filter',
        screenId: 'activity',
        title: 'Filter Activities',
        message:
            'Use filters to view specific types of activities like applications, jobs posted, or interviews.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // Job Details Screen
    hints.addAll([
      HintModel(
        id: 'job_details_apply',
        screenId: 'job_details',
        title: 'Apply to Jobs',
        message:
            'Review job details carefully before applying. Ensure you meet the requirements.',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'job_details_save',
        screenId: 'job_details',
        title: 'Save Jobs',
        message: 'Save jobs you\'re interested in to review and apply later.',
        type: HintType.tip,
        priority: 2,
      ),
    ]);

    // CV Document Viewer Screen
    hints.addAll([
      HintModel(
        id: 'cv_viewer_download',
        screenId: 'cv_document_viewer',
        title: 'View CV',
        message:
            'View candidate CVs in detail. Download or share CVs as needed.',
        type: HintType.info,
        priority: 2,
      ),
    ]);

    // Video Resume Viewer Screen
    hints.addAll([
      HintModel(
        id: 'video_resume_viewer_watch',
        screenId: 'video_resume_viewer',
        title: 'Watch Video Resume',
        message:
            'Watch candidate video resumes to get a better sense of their communication skills and personality.',
        type: HintType.info,
        priority: 2,
      ),
    ]);

    // Login Screen - No hints needed (straightforward screen)
    // Signup Screen - No hints needed (straightforward screen)
    // Introduction Screen - No hints needed (straightforward onboarding)

    // Admin Setup Screen
    hints.addAll([
      HintModel(
        id: 'admin_setup_important',
        screenId: 'admin_setup_screen',
        title: 'Initial Configuration',
        message:
            'Complete all setup steps carefully. This configuration is crucial for the app to function properly.',
        type: HintType.warning,
        priority: 5,
      ),
    ]);

    // Gig Posting Screen
    hints.addAll([
      HintModel(
        id: 'gig_posting_details',
        screenId: 'gig_posting_screen',
        title: 'Clear Gig Description',
        message:
            'Provide a clear description of the gig, including requirements, timeline, and compensation details.',
        type: HintType.tip,
        priority: 4,
      ),
      HintModel(
        id: 'gig_posting_budget',
        screenId: 'gig_posting_screen',
        title: 'Set Fair Budget',
        message:
            'Set a competitive budget that reflects the work required. This attracts quality freelancers.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Welcome Screen
    hints.addAll([
      HintModel(
        id: 'welcome_get_started',
        screenId: 'welcome_screen',
        title: 'Get Started',
        message:
            'Choose "Sign Up" to create a new account or "Sign In" if you already have one. Select your role (Job Seeker, Employer, or Trainer) during signup.',
        type: HintType.info,
        priority: 5,
      ),
      HintModel(
        id: 'welcome_admin',
        screenId: 'welcome_screen',
        title: 'Admin Access',
        message:
            'Administrators can access the admin panel by tapping the logo 5 times.',
        type: HintType.info,
        priority: 2,
      ),
    ]);

    // Admin Login Screen
    hints.addAll([
      HintModel(
        id: 'admin_login_credentials',
        screenId: 'admin_login_screen',
        title: 'Admin Credentials',
        message:
            'Use your admin email and password to sign in. Contact the system administrator if you need access.',
        type: HintType.warning,
        priority: 4,
      ),
    ]);

    // Home Screen (Main Navigation)
    hints.addAll([
      HintModel(
        id: 'home_navigation',
        screenId: 'home_screen',
        title: 'Navigate Your App',
        message:
            'Use the bottom navigation to switch between Home, Search, Activity, and Profile. Each tab provides different features based on your role.',
        type: HintType.info,
        priority: 4,
      ),
      HintModel(
        id: 'home_role_based',
        screenId: 'home_screen',
        title: 'Role-Based Features',
        message:
            'The home screen adapts to your role. Job Seekers see job recommendations, Employers see their dashboard, and Trainers see their courses.',
        type: HintType.tip,
        priority: 3,
      ),
    ]);

    // Filter out monetization hints if monetization is disabled
    return hints.where((hint) {
      if (hint.requiresMonetization && !monetizationEnabled) {
        return false;
      }
      return true;
    }).toList();
  }
}
