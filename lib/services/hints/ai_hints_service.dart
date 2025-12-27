import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/models/hint_model.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/services/hints/hints_config.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';

/// AI-Powered Hints Service
/// Generates contextual, smart hints using Gemini AI
/// NO FALLBACKS - If AI fails, returns empty list (so we know AI is not working)
class AIHintsService {
  static final AIHintsService _instance = AIHintsService._internal();
  factory AIHintsService() => _instance;
  AIHintsService._internal();

  final GeminiAIService _aiService = GeminiAIService();
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Cache for AI-generated hints (5 minute TTL)
  final Map<String, _CachedHint> _hintCache = {};
  static const _cacheTTL = Duration(minutes: 5);

  /// Generate AI-powered hints for a screen
  /// Returns empty list if AI is not available (NO FALLBACK)
  /// 
  /// [screenId] - The screen identifier (e.g., 'job_seekers_home', 'cv_builder')
  /// [userRole] - The current user's role
  /// [monetizationEnabled] - Whether monetization features are enabled
  /// [screenContext] - Optional context about the screen (features, actions available)
  Future<List<HintModel>> generateHintsForScreen({
    required String screenId,
    required AppUserRole userRole,
    required bool monetizationEnabled,
    String? screenContext,
  }) async {
    // Check cache first
    final cacheKey = _generateCacheKey(screenId, userRole, monetizationEnabled);
    if (_hintCache.containsKey(cacheKey)) {
      final cached = _hintCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
        return cached.hints;
      } else {
        _hintCache.remove(cacheKey);
      }
    }

    try {
      // Ensure AI service is initialized
      await _aiService.initialize();

      // Get existing hints for this screen to learn from
      final existingHints = HintsConfig.getHintsForScreen(
        screenId,
        monetizationEnabled: monetizationEnabled,
      );

      // Get user context for personalized hints
      final userContext = await _getUserContext(userRole);

      // Generate AI hints using direct model access
      final aiHints = await _generateAIHints(
        screenId: screenId,
        userRole: userRole,
        monetizationEnabled: monetizationEnabled,
        existingHints: existingHints,
        userContext: userContext,
        screenContext: screenContext,
      );

      // Cache the results
      _hintCache[cacheKey] = _CachedHint(
        hints: aiHints,
        timestamp: DateTime.now(),
      );

      return aiHints;
    } catch (e) {
      // NO FALLBACK - Return empty list if AI fails
      // This ensures we know when AI is not working
      debugPrint('❌ AI Hints generation failed for $screenId: $e');
      return [];
    }
  }

  /// Generate AI hints using Gemini
  /// Throws exception if AI is not available (NO FALLBACK)
  Future<List<HintModel>> _generateAIHints({
    required String screenId,
    required AppUserRole userRole,
    required bool monetizationEnabled,
    required List<HintModel> existingHints,
    required Map<String, dynamic> userContext,
    String? screenContext,
  }) async {
    // Build learning prompt from existing hints
    final hintsExamples = existingHints.map((h) => '''
- Type: ${h.type.name}
- Title: ${h.title}
- Message: ${h.message}
- Priority: ${h.priority}
''').join('\n');

    // Build codebase context prompt
    final codebaseContext = _getCodebaseContext(screenId);

    // Build comprehensive prompt
    final prompt = '''
You are an AI assistant that generates helpful, contextual hints for users in a job marketplace app.

SCREEN CONTEXT:
Screen ID: $screenId
User Role: ${userRole.name}
Monetization Enabled: $monetizationEnabled
${screenContext != null ? 'Screen Features: $screenContext' : ''}

USER CONTEXT:
${jsonEncode(userContext)}

EXISTING HINTS (Learn from these patterns):
$hintsExamples

CODEBASE CONTEXT:
$codebaseContext

TASK:
Generate 1-3 smart, contextual hints for this screen. Hints should:
1. Be specific to the screen and user role
2. Help users discover features they might miss
3. Be actionable and clear
4. Consider monetization status if relevant
5. Be personalized based on user context when possible
6. Follow the style and tone of existing hints

Return ONLY valid JSON array with this exact structure:
[
  {
    "id": "ai_hint_1",
    "title": "Short title (max 30 chars)",
    "message": "Helpful message (max 150 chars)",
    "type": "ai",
    "priority": 5,
    "requiresMonetization": false
  }
]

Prioritize hints that:
- Help users discover powerful features
- Guide users through complex workflows
- Warn about important actions
- Provide tips that improve user experience

Do NOT:
- Repeat existing hints exactly
- Generate generic hints
- Include hints that don't apply to this screen
- Generate more than 3 hints
''';

    try {
      // Use a helper method to generate content directly
      // This will throw if AI is not ready (NO FALLBACK)
      final response = await _generateContent(prompt);

      if (response.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Parse JSON response
      final jsonData = _decodeJsonList(response);

      // Convert to HintModel list
      final hints = jsonData.map((hintData) {
        return HintModel(
          id: hintData['id']?.toString() ?? 'ai_hint_${DateTime.now().millisecondsSinceEpoch}',
          title: hintData['title']?.toString() ?? 'AI Tip',
          message: hintData['message']?.toString() ?? '',
          screenId: screenId,
          type: HintType.ai,
          requiresMonetization: hintData['requiresMonetization'] == true,
          priority: _validateHintPriority(hintData['priority']),
        );
      }).toList();

      return hints;
    } catch (e) {
      debugPrint('❌ Error generating AI hints: $e');
      rethrow; // NO FALLBACK - let it fail
    }
  }

  /// Generate content using Gemini AI
  /// Throws exception if AI is not available (NO FALLBACK)
  Future<String> _generateContent(String prompt) async {
    // Initialize AI service
    await _aiService.initialize();

    // Use the new public method for generating content
    // This will throw if AI is not ready (NO FALLBACK)
    try {
      final response = await _aiService.generateContentFromPrompt(prompt);
      return response;
    } catch (e) {
      debugPrint('❌ AI content generation failed: $e');
      rethrow; // NO FALLBACK
    }
  }

  /// Get user context for personalized hints
  Future<Map<String, dynamic>> _getUserContext(AppUserRole userRole) async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      return {'role': userRole.name};
    }

    try {
      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc == null) {
        return {'role': userRole.name};
      }

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      
      // Extract relevant context
      return {
        'role': userRole.name,
        'hasCV': userData.containsKey('cv') || userData.containsKey('cvId'),
        'hasProfilePhoto': userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty,
        'accountAge': _calculateAccountAge(userData['createdAt']),
        'isVerified': userData['isVerified'] == true || userData['isCompanyVerified'] == true,
      };
    } catch (e) {
      debugPrint('Error getting user context: $e');
      return {'role': userRole.name};
    }
  }

  /// Get codebase context for a screen
  String _getCodebaseContext(String screenId) {
    // Map screen IDs to codebase context
    final contextMap = {
      'job_seekers_home': '''
This is the job seeker dashboard. Features include:
- AI Job Matching button
- Wallet balance display (if monetization enabled)
- Tools section (CV Builder, Interview Coach, Career Roadmap)
- Recently posted jobs list
- Quick actions for deposits and history
''',
      'cv_builder': '''
This is a multi-step CV builder. Features include:
- Step-by-step form with validation
- Personal info, education, experience, skills sections
- Support for non-formal education
- Languages, certifications, and projects sections
- Progress indicator
- Save and preview functionality
''',
      'job_matching': '''
This screen shows AI-powered job matches. Features include:
- Match score percentage for each job
- AI reasoning for why job matches
- Missing skills indicators
- View job details button
- Empty state if no CV or no matches
''',
      'employers_home': '''
This is the employer dashboard. Features include:
- Post a Job button
- Active jobs count
- Applications count
- Interview scheduling
- Candidate suggestions via AI
- Recent activities feed
''',
      'job_posting': '''
Screen for posting new jobs. Features include:
- Job title, description, requirements
- Category, location, salary
- Experience level selection
- Payment required (if monetization enabled)
- Form validation
''',
      'application_review': '''
Screen for reviewing job applications. Features include:
- List of applicants with CV previews
- AI-powered candidate insights
- Quick contact buttons (email, phone, WhatsApp)
- View full CV option
- Accept/reject actions
''',
      'trainers_home': '''
This is the trainer dashboard. Features include:
- Create Course button
- Live Sessions scheduling
- Course analytics
- Student count
- Rating display
''',
      'courses': '''
Screen for managing courses. Features include:
- Create new courses
- Edit existing courses
- Publish/unpublish courses
- Course content management
- Student enrollment tracking
''',
      'admin_panel': '''
Admin control panel. Features include:
- Company approval/rejection
- Job posting moderation
- API settings configuration
- Monetization controls
- Finance management
- Statistics dashboard
''',
      'search': '''
Job search screen. Features include:
- Keyword search
- Category filters
- Location filters
- Experience level filters
- AI-powered smart search
- Save search functionality
''',
      'chat': '''
Individual chat screen. Features include:
- Message history
- Send text messages
- Real-time updates
- Notification integration
- User profile display
''',
      'wallet': '''
Wallet management screen. Features include:
- Current balance display
- Deposit functionality
- Transaction history
- Top-up requests (if monetization enabled)
''',
      'profile': '''
User profile screen. Features include:
- Profile photo
- Contact information
- Edit profile button
- Settings access
- Logout option
''',
    };

    return contextMap[screenId] ?? 'Screen context not available for $screenId';
  }

  /// Calculate account age in days
  int _calculateAccountAge(dynamic createdAt) {
    if (createdAt == null) return 0;
    
    DateTime? createdDate;
    if (createdAt is Timestamp) {
      createdDate = createdAt.toDate();
    } else if (createdAt is String) {
      createdDate = DateTime.tryParse(createdAt);
    } else if (createdAt is DateTime) {
      createdDate = createdAt;
    }

    if (createdDate == null) return 0;
    
    return DateTime.now().difference(createdDate).inDays;
  }

  /// Generate cache key
  String _generateCacheKey(String screenId, AppUserRole userRole, bool monetizationEnabled) {
    return '${screenId}_${userRole.name}_$monetizationEnabled';
  }

  /// Decode JSON from AI response
  List<Map<String, dynamic>> _decodeJsonList(String text) {
    try {
      // Try to extract JSON from markdown code blocks
      String jsonText = text.trim();
      if (jsonText.startsWith('```')) {
        final lines = jsonText.split('\n');
        jsonText = lines
            .where((line) => !line.startsWith('```'))
            .join('\n')
            .trim();
      }

      // Try parsing as JSON
      final decoded = jsonDecode(jsonText);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      } else if (decoded is Map) {
        // Sometimes AI returns a single object in a map
        return [decoded.map((k, v) => MapEntry(k.toString(), v))];
      }
      return [];
    } catch (e) {
      debugPrint('Error decoding AI hints JSON: $e');
      debugPrint('Raw response: $text');
      rethrow;
    }
  }

  /// Generate AI hint for a specific input field
  /// Returns a concise, actionable hint string (not HintModel)
  /// Used for inline field-level hints with AI tooltip buttons
  Future<String?> generateFieldHint({
    required String fieldName, // e.g., 'job_title', 'cv_skills'
    required String screenId, // e.g., 'job_posting', 'cv_builder'
    required AppUserRole userRole,
    required bool monetizationEnabled,
  }) async {
    try {
      await _aiService.initialize();

      // Get field-specific context
      final fieldContext = _getFieldContext(fieldName, screenId);

      // Build field hint prompt
      final prompt = '''
You are an AI assistant helping users fill out forms in a job marketplace app.

FIELD TO HELP WITH:
Field Name: $fieldName
Screen: $screenId
Field Context: $fieldContext

USER ROLE: ${userRole.name}
MONETIZATION ENABLED: $monetizationEnabled

TASK:
Generate a single, concise, actionable hint for this input field. The hint should:
1. Explain what information to enter
2. Provide 1-2 tips or examples
3. Be encouraging and helpful
4. Be 1-2 sentences max
5. Be specific to the job marketplace context

Return ONLY the hint text, no JSON, no markdown, just plain text (1-2 sentences).
''';

      final response = await _aiService.generateText(
        prompt: prompt,
        maxTokens: 100,
      );

      // Extract and return the hint text
      if (response.isNotEmpty) {
        return response.trim();
      }

      return null;
    } catch (e) {
      debugPrint('❌ Field hint generation failed for $fieldName: $e');
      return null;
    }
  }

  /// Get context information for a specific field
  String _getFieldContext(String fieldName, String screenId) {
    final contexts = {
      // Job Posting Fields
      'job_title': 'The primary title of the job being posted',
      'job_description': 'Detailed description of the job responsibilities and requirements',
      'job_requirements': 'Required skills, experience, and qualifications',
      'salary_min': 'Minimum salary or salary range start',
      'salary_max': 'Maximum salary or salary range end',
      'job_category': 'Industry or job category classification',
      'experience_level': 'Required level of experience (entry, mid, senior)',
      'employment_type': 'Type of employment (full-time, part-time, contract, etc.)',

      // CV Builder Fields
      'full_name': 'Your complete first and last name',
      'email': 'Professional email address for contact',
      'phone': 'Phone number employers can use to reach you',
      'cv_title': 'Professional headline or job title for your CV',
      'cv_summary': 'Brief summary of your professional background and goals',
      'cv_skills': 'List of professional skills and competencies',
      'work_experience': 'Previous job positions and responsibilities',
      'education': 'Educational background and qualifications',
      'certifications': 'Professional certifications and credentials',
      'languages': 'Languages you speak and proficiency level',

      // Profile Fields
      'bio': 'Personal or professional biography',
      'location': 'City or region where you are based',
      'portfolio_url': 'Link to your professional portfolio or website',
      'linkedin_url': 'Link to your LinkedIn profile',
      'github_url': 'Link to your GitHub profile (for developers)',

      // Interview Coach
      'interview_topic': 'Topic or job role for interview practice',
      'interview_response': 'Your answer to the interview question',

      // Career Roadmap
      'career_goal': 'Your career goals and aspirations',
      'skills_to_learn': 'Skills you want to develop',
      'timeline': 'Timeframe for achieving your goals',
    };

    return contexts[fieldName] ?? 'Fill in this field';
  }

  /// Clear cache (useful after settings changes)
  void clearCache() {
    _hintCache.clear();
  }
}

/// Cache entry for AI hints
class _CachedHint {
  final List<HintModel> hints;
  final DateTime timestamp;

  _CachedHint({
    required this.hints,
    required this.timestamp,
  });
}
/// Helper method to validate hint priority
int _validateHintPriority(dynamic rawPriority) {
  try {
    final priority = (rawPriority as num?)?.toInt();
    if (priority == null) {
      debugPrint('⚠️ Warning: Hint priority missing, using default 5');
      return 5;
    }
    if (priority < 1 || priority > 10) {
      debugPrint('⚠️ Warning: Invalid hint priority $priority, clamping to 1-10');
      return priority.clamp(1, 10);
    }
    return priority;
  } catch (e) {
    debugPrint('⚠️ Warning: Failed to parse hint priority: $e, using default 5');
    return 5;
  }
}