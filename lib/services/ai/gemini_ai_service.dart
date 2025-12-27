import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart'; // No longer needed - using local Gemini
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:freelance_app/services/config/api_keys_service.dart';

/// Google Gemini AI Service
/// FREE TIER: 60 requests/minute, 1,500 requests/day
/// Perfect for CV analysis, job matching, and recommendations
///
/// IMPORTANT: All methods throw errors when AI is not available.
/// NO FALLBACK METHODS - AI must be properly configured.
///
/// API keys can be configured via:
/// 1. Admin Portal (recommended for production) - stored in Firestore
/// 2. Environment variables (for development) - `--dart-define=GEMINI_API_KEY=...`
class GeminiAIService {
  static final GeminiAIService _instance = GeminiAIService._internal();
  factory GeminiAIService() => _instance;
  GeminiAIService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final APIKeysService _apiKeysService = APIKeysService();

  // ═══════════════════════════════════════════════════════════════
  // CONFIGURATION - GEMINI API KEY
  // ═══════════════════════════════════════════════════════════════
  /// Google Gemini API Key - FREE Tier: 1,500 requests/day
  /// Priority: 1. Firestore (Admin Portal) 2. Environment variable (dev)
  String _geminiApiKey = '';
  String _modelName = 'gemini-1.5-flash';

  /// Get API key from Firestore or environment variable
  String get geminiApiKey => _geminiApiKey;

  /// Get model name from Firestore or environment variable
  String get modelName => _modelName;

  // ═══════════════════════════════════════════════════════════════

  GenerativeModel? _model;
  bool _initialized = false;

  // ═══════════════════════════════════════════════════════════════
  // RESILIENCE & QUOTA MANAGEMENT
  // ═══════════════════════════════════════════════════════════════
  final Map<String, Map<String, dynamic>> _memoryCache = {};
  final Map<String, Map<String, dynamic>> _matchCache = {}; // Cache for job-candidate matches (7-day TTL)
  DateTime? _circuitBreakerUntil;
  bool get _isCircuitBreakerActive =>
      _circuitBreakerUntil != null &&
      DateTime.now().isBefore(_circuitBreakerUntil!);

  // ═══════════════════════════════════════════════════════════════
  // MATCH CACHING CONSTANTS
  // ═══════════════════════════════════════════════════════════════
  static const String _matchCacheCollection = 'job_candidate_match_cache';
  static const int _matchCacheDays = 7; // Cache job-candidate matches for 7 days

  // ═══════════════════════════════════════════════════════════════
  // RESILIENCE HELPERS
  // ═══════════════════════════════════════════════════════════════

  String _generateCacheKey(String method, String input) {
    if (input.length > 200) {
      return '${method}_${input.substring(0, 50)}_${input.length}_${input.substring(input.length - 50)}';
    }
    return '${method}_$input';
  }

  void _handleQuotaError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('429') ||
        errorStr.contains('quota') ||
        errorStr.contains('limit') ||
        errorStr.contains('rate')) {
      _circuitBreakerUntil = DateTime.now().add(const Duration(minutes: 5));
      debugPrint('⚠️ AI Quota Hit. Circuit breaker active for 5 minutes.');
    }
  }

  /// Throws an exception if AI is not ready
  /// Automatically fetches latest API keys from database before checking
  Future<void> _ensureReady() async {
    // Always fetch latest keys from database before use
    try {
      await _loadAndRefreshKeys();
    } catch (e) {
      debugPrint('❌ Error loading API keys in _ensureReady: $e');
      // Continue to check if model exists anyway
    }

    if (!_isReady) {
      final errorMsg = _geminiApiKey.isEmpty
          ? 'AI service is not ready. Please configure GEMINI_API_KEY via Admin Portal or ensure Firebase Functions are set up.'
          : 'AI service is not ready. Model initialization failed. Please check API key configuration.';
      debugPrint(
          '❌ _isReady check failed. API Key empty: ${_geminiApiKey.isEmpty}, Model null: ${_model == null}, Initialized: $_initialized');
      throw Exception(errorMsg);
    }
    if (_isCircuitBreakerActive) {
      throw Exception(
          'AI service is temporarily unavailable due to quota limits. Please try again in a few minutes.');
    }
  }

  /// Standard AI Operation Wrapper
  /// Ensures consistent error handling, logging, and quota management across all AI features
  /// This is the recommended pattern for all AI methods
  Future<T> _aiOperation<T>({
    required String operationName,
    required Future<T> Function() operation,
  }) async {
    await _ensureReady();

    try {
      debugPrint('🚀 [$operationName] Starting...');
      final result = await operation();
      debugPrint('✅ [$operationName] Completed successfully');
      return result;
    } on FirebaseException catch (e) {
      debugPrint('❌ [$operationName] Firebase error: ${e.code} - ${e.message}');
      _handleQuotaError(e);
      rethrow;
    } catch (e) {
      debugPrint('❌ [$operationName] Error: $e');
      _handleQuotaError(e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════

  bool get _isConfigured => _geminiApiKey.trim().isNotEmpty;
  bool get _isReady => _model != null && _isConfigured && _initialized;

  /// Initialize AI service (called once at app startup)
  /// Loads API key from Firestore (Admin Portal) or environment variable
  Future<void> initialize() async {
    await _loadAndRefreshKeys();
    _initialized = true;
  }

  /// Load API keys from database and refresh model if needed
  /// This is called automatically before each AI operation
  Future<void> _loadAndRefreshKeys() async {
    String? previousApiKey = _geminiApiKey;
    String? previousModel = _modelName;

    // Always clear cache to ensure fresh data from Firestore
    // This prevents stale 1-minute cached keys when user updates settings
    _apiKeysService.clearCache();

    // Try to load from Firestore first (Admin Portal configuration)
    try {
      final apiKeys = await _apiKeysService.getAllKeys();
      _geminiApiKey = apiKeys['gemini_api_key'] ?? '';
      _modelName = apiKeys['gemini_model'] ?? 'gemini-1.5-flash';

      if (_geminiApiKey.isEmpty) {
        // Fallback to environment variable for development
        _geminiApiKey =
            const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
        _modelName = const String.fromEnvironment('GEMINI_MODEL',
            defaultValue: 'gemini-1.5-flash');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading API keys from Firestore: $e');
      // Fallback to environment variable
      _geminiApiKey =
          const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      _modelName = const String.fromEnvironment('GEMINI_MODEL',
          defaultValue: 'gemini-1.5-flash');
    }

    // Refresh model if API key or model changed
    if (_isConfigured) {
      final keysChanged =
          previousApiKey != _geminiApiKey || previousModel != _modelName;

      if (keysChanged || _model == null) {
        try {
          _model = GenerativeModel(
            model: _modelName,
            apiKey: _geminiApiKey,
          );
          debugPrint('✅ AI model refreshed: $_modelName');
          // Mark as initialized once model is successfully created
          _initialized = true;
        } catch (e) {
          debugPrint('❌ Error initializing Gemini AI (local model): $e');
          _model = null;
        }
      } else {
        // Model already exists and keys haven't changed, ensure initialized flag is set
        _initialized = true;
      }
    } else {
      _model = null;
      debugPrint(
          '⚠️ Gemini API key not configured. Configure via Admin Portal or environment variable.');
    }
  }

  String _stripCodeFences(String input) {
    final trimmed = input.trim();
    if (!trimmed.startsWith('```')) return trimmed;

    final lines = trimmed.split('\n');
    if (lines.isEmpty) return trimmed;

    if (lines.first.trim().startsWith('```')) {
      lines.removeAt(0);
    }
    if (lines.isNotEmpty && lines.last.trim() == '```') {
      lines.removeLast();
    }
    return lines.join('\n').trim();
  }

  String _extractFirstJson(String input) {
    final text = _stripCodeFences(input);

    final arrayStart = text.indexOf('[');
    final objStart = text.indexOf('{');
    final start = (arrayStart == -1)
        ? objStart
        : (objStart == -1
            ? arrayStart
            : (arrayStart < objStart ? arrayStart : objStart));
    if (start == -1) return text;

    final endChar = text[start] == '[' ? ']' : '}';
    final end = text.lastIndexOf(endChar);
    if (end == -1 || end <= start) return text.substring(start);
    return text.substring(start, end + 1);
  }

  Map<String, dynamic> _decodeJsonMap(String text) {
    final candidate = _extractFirstJson(text);
    final decoded = jsonDecode(candidate);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
    throw const FormatException('Expected JSON object');
  }

  List<Map<String, dynamic>> _decodeJsonListOfMaps(String text) {
    final candidate = _extractFirstJson(text);
    final decoded = jsonDecode(candidate);
    if (decoded is! List) {
      throw const FormatException('Expected JSON array');
    }
    return decoded
        .whereType<dynamic>()
        .map<Map<String, dynamic>>((e) {
          if (e is Map<String, dynamic>) return e;
          if (e is Map) {
            return e.map((k, v) => MapEntry(k.toString(), v));
          }
          return <String, dynamic>{};
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Analyze CV and extract skills, experience, education
  /// STANDARDIZED PATTERN: Uses local Gemini with fresh API keys
  /// Throws exception if AI is not available
  Future<Map<String, dynamic>> analyzeCV({
    required String cvText,
    required String userId,
  }) async {
    return _aiOperation(
      operationName: 'analyzeCV',
      operation: () async {
        final cacheKey = _generateCacheKey('analyzeCV', cvText);
        if (_memoryCache.containsKey(cacheKey)) {
          debugPrint('📋 [Analyze] Returning cached CV analysis');
          return _memoryCache[cacheKey]!;
        }

        final prompt = '''
Analyze this CV and extract structured information. Return ONLY valid JSON with this exact structure:
{
  "skills": ["skill1", "skill2", ...],
  "experienceYears": number,
  "education": ["degree1", "degree2", ...],
  "languages": ["language1", "language2", ...],
  "summary": "brief professional summary",
  "strengths": ["strength1", "strength2", ...],
  "jobTitles": ["title1", "title2", ...]
}

CV Text:
$cvText
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        if (text.isEmpty) {
          throw Exception('Empty response from AI');
        }

        // Parse JSON response
        final jsonData = _decodeJsonMap(text);

        // Save to cache
        _memoryCache[cacheKey] = jsonData;

        // Save analysis to Firestore for auto-training
        await _saveAnalysisToDatabase(userId, jsonData);

        return jsonData;
      },
    );
  }

  /// Get cached job-candidate match from Firestore (7-day TTL)
  /// Checks: Memory cache → Firestore cache → returns null if not found
  Future<Map<String, dynamic>?> _getCachedMatch(String jobId, String candidateId) async {
    try {
      final cacheKey = 'match_${jobId}_$candidateId';

      // Check memory cache first (fastest)
      if (_matchCache.containsKey(cacheKey)) {
        debugPrint('📊 [Match Cache] Memory hit: $jobId vs $candidateId');
        return _matchCache[cacheKey];
      }

      // Check Firestore cache
      final doc = await _firestore.collection(_matchCacheCollection).doc(cacheKey).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['created_at'] as Timestamp?;
        final cutoff = DateTime.now().subtract(Duration(days: _matchCacheDays));

        if (createdAt?.toDate().isAfter(cutoff) ?? false) {
          debugPrint('📊 [Match Cache] Firestore hit: $jobId vs $candidateId (7-day TTL)');
          final result = data['match_result'] as Map<String, dynamic>;
          _matchCache[cacheKey] = result; // Store in memory for this session
          return result;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Match Cache] Retrieval failed: $e');
      // Silently fail - caching is optional
    }
    return null;
  }

  /// Bank job-candidate match result to Firestore for 7-day persistence
  Future<void> _cacheMatch(String jobId, String candidateId, Map<String, dynamic> result) async {
    try {
      final cacheKey = 'match_${jobId}_$candidateId';
      _matchCache[cacheKey] = result; // Store in memory immediately

      await _firestore.collection(_matchCacheCollection).doc(cacheKey).set({
        'job_id': jobId,
        'candidate_id': candidateId,
        'match_result': result,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      }, SetOptions(merge: true));

      debugPrint('✅ [Match Cache] Banked to Firestore: $jobId vs $candidateId');
    } catch (e) {
      debugPrint('⚠️ [Match Cache] Banking failed: $e');
      // Silently fail - caching is optional
    }
  }

  /// Match job seeker to job using AI
  /// STANDARDIZED PATTERN: Uses local Gemini with fresh API keys
  /// Throws exception if AI is not available
  Future<Map<String, dynamic>> matchJobToCandidate({
    required String jobId,                          // NEW: for caching
    required String candidateId,                    // NEW: for caching
    required Map<String, dynamic> candidateProfile,
    required Map<String, dynamic> jobRequirements,
  }) async {
    return _aiOperation(
      operationName: 'matchJobToCandidate',
      operation: () async {
        // Check Firestore cache first (2-tier cache for matching)
        final cachedMatch = await _getCachedMatch(jobId, candidateId);
        if (cachedMatch != null) {
          return cachedMatch;
        }

        final cacheKey = _generateCacheKey('match',
            '${jsonEncode(candidateProfile)}_${jsonEncode(jobRequirements)}');
        if (_memoryCache.containsKey(cacheKey)) {
          debugPrint('🎯 [Match] Returning cached match result');
          return _memoryCache[cacheKey]!;
        }

        final prompt = '''
${_getCurrencyConversionInstruction()}

Analyze this job seeker profile and job requirements. Calculate a match score (0-100) and provide reasoning.

Candidate Profile:
${jsonEncode(candidateProfile)}

Job Requirements:
${jsonEncode(jobRequirements)}

Return ONLY valid JSON:
{
  "matchScore": number (0-100),
  "reasoning": "why this is a good/bad match",
  "missingSkills": ["skill1", "skill2"],
  "matchingSkills": ["skill1", "skill2"],
  "recommendations": ["recommendation1", "recommendation2"]
}
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        if (text.isEmpty) {
          throw Exception('Empty response from AI');
        }
        final jsonData = _decodeJsonMap(text);

        _memoryCache[cacheKey] = jsonData;
        
        // Bank the match result for 7-day persistence
        await _cacheMatch(jobId, candidateId, jsonData);
        
        return jsonData;
      },
    );
  }

  /// Generate personalized job recommendations
  /// Throws exception if AI is not available
  Future<List<Map<String, dynamic>>> recommendJobs({
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> availableJobs,
  }) async {
    final cacheKey = _generateCacheKey(
        'recommend', '${jsonEncode(userProfile)}_${availableJobs.length}');
    if (_memoryCache.containsKey(cacheKey)) {
      // For lists, we store them as a Map with a special key
      return List<Map<String, dynamic>>.from(_memoryCache[cacheKey]!['items']);
    }

    await _ensureReady();

    try {
      final prompt = '''
${_getCurrencyConversionInstruction()}

Based on this user profile, rank these jobs from best to worst match. Return up to 20.

User Profile:
${jsonEncode(userProfile)}

Available Jobs:
${jsonEncode(availableJobs)}

Note: If any jobs have salary information in currencies other than BWP, convert them to BWP in your reasoning.

Return ONLY a valid JSON array (no markdown, no code fences):
[
  {"jobId": "id", "matchScore": number, "reason": "why"},
  ...
]
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      if (text.isEmpty) {
        throw Exception('Empty response from AI');
      }
      final results = _decodeJsonListOfMaps(text);

      _memoryCache[cacheKey] = {'items': results};
      return results;
    } catch (e) {
      debugPrint('❌ Error recommending jobs: $e');
      _handleQuotaError(e);
      rethrow;
    }
  }

  /// Recommend jobs with recent in-app signals included in the prompt.
  /// STANDARDIZED PATTERN: Uses local Gemini for reliability
  /// Throws exception if AI is not available
  Future<List<Map<String, dynamic>>> recommendJobsForUser({
    required String userId,
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> availableJobs,
  }) async {
    return _aiOperation(
      operationName: 'recommendJobsForUser',
      operation: () async {
        // Check cache first
        final cacheKey = _generateCacheKey(
            'recommend_user', '${jsonEncode(userProfile)}_${availableJobs.length}');
        if (_memoryCache.containsKey(cacheKey)) {
          debugPrint('📊 [Recommend] Returning cached recommendations');
          return List<Map<String, dynamic>>.from(_memoryCache[cacheKey]!['items']);
        }

        // Include recent job signals for better ranking
        final signals = await _getRecentJobSignals(userId);
        final enrichedProfile = <String, dynamic>{
          ...userProfile,
          if (signals.isNotEmpty) 'recentSignals': signals,
        };

        final prompt = '''
${_getCurrencyConversionInstruction()}

Based on this user profile, rank these jobs from best to worst match. Return up to 20.

User Profile:
${jsonEncode(enrichedProfile)}

Available Jobs:
${jsonEncode(availableJobs)}

Note: If any jobs have salary information in currencies other than BWP, convert them to BWP in your reasoning.

Return ONLY a valid JSON array (no markdown, no code fences):
[
  {"jobId": "id", "matchScore": number, "reason": "why"},
  ...
]
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        if (text.isEmpty) {
          throw Exception('Empty response from AI');
        }
        
        final results = _decodeJsonListOfMaps(text);
        
        // Validate results
        if (results.isEmpty) {
          debugPrint('⚠️ [Recommend] No recommendations returned');
          return const [];
        }

        // Cache results
        _memoryCache[cacheKey] = {'items': results};
        debugPrint('✅ [Recommend] Ranked ${results.length} jobs');
        return results;
      },
    );
  }

  /// Legacy method - forwards to new standardized recommendJobsForUser
  /// Deprecated: Use recommendJobsForUser instead
  @Deprecated('Use recommendJobsForUser with userId instead')
  Future<List<Map<String, dynamic>>> recommendJobsForUserLegacy({
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> availableJobs,
  }) async {
    return _aiOperation(
      operationName: 'recommendJobsForUserLegacy',
      operation: () async {
        final cacheKey = _generateCacheKey(
            'recommend', '${jsonEncode(userProfile)}_${availableJobs.length}');
        if (_memoryCache.containsKey(cacheKey)) {
          return List<Map<String, dynamic>>.from(_memoryCache[cacheKey]!['items']);
        }

        final prompt = '''
${_getCurrencyConversionInstruction()}

Based on this user profile, rank these jobs from best to worst match. Return up to 20.

User Profile:
${jsonEncode(userProfile)}

Available Jobs:
${jsonEncode(availableJobs)}

Note: If any jobs have salary information in currencies other than BWP, convert them to BWP in your reasoning.

Return ONLY a valid JSON array (no markdown, no code fences):
[
  {"jobId": "id", "matchScore": number, "reason": "why"},
  ...
]
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        if (text.isEmpty) {
          throw Exception('Empty response from AI');
        }
        final results = _decodeJsonListOfMaps(text);

        _memoryCache[cacheKey] = {'items': results};
        return results;
      },
    );
  }

  /// Employer-side: rank candidates for a job posting.
  /// STANDARDIZED PATTERN: Uses local Gemini with fallback to backend if needed.
  /// Returns a list of: { userId, matchScore, reason }
  /// Throws exception if AI is not available
  Future<List<Map<String, dynamic>>> recommendCandidatesForJob({
    required Map<String, dynamic> job,
    required List<Map<String, dynamic>> candidates,
    int maxResults = 10,
  }) async {
    return _aiOperation(
      operationName: 'recommendCandidatesForJob',
      operation: () async {
        final cacheKey = _generateCacheKey(
            'candidates', '${jsonEncode(job)}_${candidates.length}');
        
        // Check cache first
        if (_memoryCache.containsKey(cacheKey)) {
          debugPrint('📋 [Candidates] Returning cached recommendations');
          final cached = _memoryCache[cacheKey]!['_items'] as List<dynamic>;
          return cached.cast<Map<String, dynamic>>();
        }

        final jobTitle = job['title'] ?? 'Unknown Position';
        final requiredSkills = (job['requiredSkills'] as List?)?.join(', ') ?? 'Not specified';
        final descriptionSnippet = (job['description'] as String?)?.substring(0, 500) ?? '';

        final prompt = '''
Analyze these candidates and rank them by how well they match this job posting.

**Job Title**: $jobTitle
**Required Skills**: $requiredSkills
**Description**: $descriptionSnippet

**Candidates** (with ratings from previous employers):
${jsonEncode(candidates)}

For each candidate, consider:
1. Skills match with job requirements
2. Experience level and relevance
3. Previous employer ratings (if available) - candidates with higher ratings are more reliable
4. Career progression and growth potential

Return ONLY valid JSON array (no markdown code fences):
[
  {"userId": "string", "matchScore": number (0-100), "reason": "string"},
  ...
]

Rank up to ${maxResults.clamp(1, 10)} candidates.
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        
        if (text.isEmpty) {
          throw Exception('Empty response from Gemini');
        }

        // Parse and validate JSON
        final jsonList = _decodeJsonListOfMaps(text);

        // Validate structure
        if (jsonList.isEmpty) {
          throw Exception('No candidates returned from AI ranking');
        }

        for (int i = 0; i < jsonList.length; i++) {
          final item = jsonList[i];
          if (!item.containsKey('userId') || !item.containsKey('matchScore')) {
            throw Exception(
                'Invalid candidate at index $i: missing userId or matchScore. Got keys: ${item.keys.join(", ")}');
          }
        }

        // Cache validated result
        _memoryCache[cacheKey] = {'_items': jsonList};
        debugPrint('✅ [Candidates] Ranked ${jsonList.length} candidates successfully');
        return jsonList;
      },
    );
  }

  Future<void> logJobInteraction({
    required String userId,
    required String jobId,
    required String event,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai')
          .doc('job_events')
          .collection('events')
          .add({
        'jobId': jobId,
        'event': event,
        'source': source,
        if (metadata != null) 'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
        'model': modelName,
      });
    } catch (e) {
      debugPrint('logJobInteraction error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentJobSignals(String userId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai')
          .doc('job_events')
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Auto-train from app data (CVs, jobs, user behavior)
  Future<void> trainFromAppData({
    required List<Map<String, dynamic>> cvs,
    required List<Map<String, dynamic>> jobs,
    required List<Map<String, dynamic>> successfulMatches,
  }) async {
    await _ensureReady();

    try {
      // Analyze patterns in successful matches
      final prompt = '''
Analyze these successful job matches and extract patterns:

Successful Matches:
${jsonEncode(successfulMatches)}

Return patterns that predict good matches:
{
  "skillPatterns": {...},
  "experiencePatterns": {...},
  "educationPatterns": {...}
}
''';

      await _model!.generateContent([Content.text(prompt)]);
      // Save patterns to Firestore for future use
      debugPrint('✅ Training data analyzed');
    } catch (e) {
      debugPrint('❌ Error training from data: $e');
      rethrow;
    }
  }

  /// Save analysis to database for auto-training
  Future<void> _saveAnalysisToDatabase(
    String userId,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai')
          .doc('cv_analysis')
          .set({
        'analysis': analysis,
        'updatedAt': FieldValue.serverTimestamp(),
        'model': modelName,
        'source': 'gemini',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('_saveAnalysisToDatabase error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NEW AI FEATURES - Phase 2
  // ═══════════════════════════════════════════════════════════════

  /// Generate a personalized cover letter
  /// Throws exception if AI is not available
  Future<String> generateCoverLetter({
    required Map<String, dynamic> cvData,
    required Map<String, dynamic> jobDetails,
    String tone = 'professional', // professional, friendly, enthusiastic
  }) async {
    await _ensureReady();

    try {
      final prompt = '''
Generate a compelling, personalized cover letter for this candidate applying to this job.

Guidelines:
- Be $tone in tone
- Keep it under 300 words
- Highlight relevant experience from the CV that matches job requirements
- Include specific examples of achievements
- Show enthusiasm for the role and company
- End with a clear call to action

Candidate Profile:
Name: ${cvData['name'] ?? 'Applicant'}
Skills: ${cvData['skills'] ?? []}
Experience: ${cvData['experience'] ?? 'Not specified'}
Summary: ${cvData['summary'] ?? ''}

Job Details:
Title: ${jobDetails['title'] ?? jobDetails['jobTitle']}
Company: ${jobDetails['company'] ?? jobDetails['companyName']}
Description: ${jobDetails['description'] ?? ''}
Requirements: ${jobDetails['requirements'] ?? jobDetails['requiredSkills'] ?? []}

Return ONLY the cover letter text, ready to use. Start with a greeting.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from AI');
      }
      return text;
    } catch (e) {
      debugPrint('❌ Error generating cover letter: $e');
      _handleQuotaError(e);
      rethrow;
    }
  }

  /// Generate interview questions for a specific job
  /// Throws exception if AI is not available
  Future<List<Map<String, dynamic>>> generateInterviewQuestions({
    required String jobTitle,
    required String company,
    required List<String> skills,
    String level = 'mid', // entry, mid, senior
    int count = 5,
  }) async {
    await _ensureReady();

    try {
      final prompt = '''
Generate $count interview questions for a $level-level $jobTitle position at $company.

Required skills for this role: ${skills.join(', ')}

For each question, provide:
1. The question itself
2. Category (technical, behavioral, situational, cultural fit)
3. What the interviewer is looking for
4. A sample strong answer outline

Return ONLY a valid JSON array:
[
  {
    "question": "...",
    "category": "technical|behavioral|situational|cultural",
    "lookingFor": "What the interviewer wants to hear",
    "sampleAnswer": "Key points for a strong answer"
  }
]
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      if (text.isEmpty) {
        throw Exception('Empty response from AI');
      }
      return _decodeJsonListOfMaps(text);
    } catch (e) {
      debugPrint('❌ Error generating interview questions: $e');
      _handleQuotaError(e);
      rethrow;
    }
  }

  /// Evaluate an interview answer
  /// Throws exception if AI is not available
  Future<Map<String, dynamic>> evaluateInterviewAnswer({
    required String question,
    required String answer,
    required String jobTitle,
    required String category,
  }) async {
    await _ensureReady();

    try {
      final prompt = '''
Evaluate this interview answer for a $jobTitle position.

Question ($category): $question

Candidate's Answer: $answer

Provide feedback in this exact JSON format:
{
  "score": number (1-10),
  "strengths": ["strength1", "strength2"],
  "improvements": ["improvement1", "improvement2"],
  "feedback": "Overall constructive feedback paragraph",
  "revisedAnswer": "Suggested improved version of the answer"
}
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      if (text.isEmpty) {
        throw Exception('Empty response from AI');
      }
      return _decodeJsonMap(text);
    } catch (e) {
      debugPrint('❌ Error evaluating answer: $e');
      _handleQuotaError(e);
      rethrow;
    }
  }

  /// Estimate salary for a role
  /// Throws exception if AI is not available
  Future<Map<String, dynamic>> estimateSalary({
    required String jobTitle,
    required String location,
    required int yearsExperience,
    required List<String> skills,
    String currency = 'BWP',
  }) async {
    await _ensureReady();

    try {
      final prompt = '''
${_getCurrencyConversionInstruction()}

Estimate the salary range for this position in Botswana (BWP - Pula).

Job Title: $jobTitle
Location: $location
Years of Experience: $yearsExperience
Key Skills: ${skills.join(', ')}

Consider the Botswana job market. If you reference international salary data, convert it to BWP using the exchange rates provided above.

Return ONLY valid JSON:
{
  "minimum": number (in BWP only),
  "maximum": number (in BWP only),
  "median": number (in BWP only),
  "currency": "BWP",
  "confidence": "high|medium|low",
  "factors": ["factor1", "factor2"],
  "marketInsight": "Brief market analysis"
}
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      if (text.isEmpty) {
        throw Exception('Empty response from AI');
      }
      return _decodeJsonMap(text);
    } catch (e) {
      debugPrint('❌ Error estimating salary: $e');
      _handleQuotaError(e);
      rethrow;
    }
  }

  /// Parse a natural language search query into structured filters
  /// STANDARDIZED PATTERN: Uses local Gemini with fresh API keys
  /// Throws exception if AI is not available
  Future<Map<String, dynamic>> parseSearchQuery(String query) async {
    return _aiOperation(
      operationName: 'parseSearchQuery',
      operation: () async {
        final cacheKey = _generateCacheKey('parseSearch', query);
        if (_memoryCache.containsKey(cacheKey)) {
          debugPrint('🔍 [Search] Returning cached query parse result');
          return _memoryCache[cacheKey]!;
        }

        final prompt = '''
Extract structured search filters from this user query for a job search app.

User Query: "$query"

Available Filter Categories:
- keyword: (main search term)
- location: (city, country, or "remote")
- category: (job category if explicitly mentioned, e.g., "engineering", "design", "marketing")
- jobType: (full-time, part-time, freelance, internship)
- experienceLevel: (entry, mid, senior)

Return ONLY valid JSON:
{
  "keyword": "extracted keywords",
  "location": "extracted location or null",
  "category": "extracted category or null",
  "jobType": "extracted type or null",
  "experienceLevel": "extracted level or null"
}
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        if (text.isEmpty) {
          throw Exception('Empty response from AI');
        }
        final jsonData = _decodeJsonMap(text);
        _memoryCache[cacheKey] = jsonData;
        return jsonData;
      },
    );
  }

  /// Ask the AI Assistant a question with full context
  /// Throws exception if AI is not available
  /// AI Career Assistant - Answer questions about job fit, skills, etc.
  /// STANDARDIZED PATTERN: Uses the standard AI operation wrapper
  /// Throws exception if AI is not available
  Future<String> askAIAssistant({
    required String question,
    required Map<String, dynamic> userContext,
    required Map<String, dynamic> jobContext,
  }) async {
    return _aiOperation(
      operationName: 'askAIAssistant',
      operation: () async {
        final prompt = '''
${_getCurrencyConversionInstruction()}

You are a helpful career assistant in a job search app.
Answer the user's question based on their profile and the specific job they are looking at.

User Context:
${_prettyPrintMap(userContext)}

Job Context:
${_prettyPrintMap(jobContext)}

User Question: "$question"

Keep your answer concise (under 3 sentences), encouraging, and specific to the data provided.
If the user asks if they are a fit, compare skills and experience.
If the question involves money, salary, or compensation, always provide amounts in BWP only (convert from other currencies if needed).
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text == null || text.isEmpty) {
          throw Exception('Empty response from AI');
        }
        return text;
      },
    );
  }

  String _prettyPrintMap(Map<String, dynamic> map) {
    return map.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
  }

  /// Get currency conversion instruction for AI prompts
  /// Ensures all monetary values are converted to BWP using real exchange rates
  String _getCurrencyConversionInstruction() {
    return '''
CRITICAL CURRENCY RULE: All monetary amounts MUST be in BWP (Botswana Pula).
- If you encounter salary, payment, or compensation data in USD, EUR, ZAR, or any other currency, you MUST convert it to BWP using current exchange rates.
- Do NOT just change the currency symbol - you must perform actual currency conversion.
- Current approximate exchange rates (use these or look up latest rates):
  * 1 USD ≈ 13.5 BWP
  * 1 EUR ≈ 14.7 BWP
  * 1 ZAR ≈ 0.73 BWP
  * 1 GBP ≈ 17.2 BWP
- Always display amounts in BWP format (e.g., "P 50,000 - P 80,000" or "50,000 - 80,000 BWP").
- If you're unsure of the exchange rate, use the approximate rates above or look up the current rate.
''';
  }

  /// Analyze skills gap for a target role
  /// STANDARDIZED PATTERN: Uses local Gemini with fresh API keys
  /// Throws exception if AI is not available
  Future<Map<String, dynamic>> analyzeSkillsGap({
    required List<String> currentSkills,
    required String targetJobTitle,
  }) async {
    return _aiOperation(
      operationName: 'analyzeSkillsGap',
      operation: () async {
        final cacheKey = _generateCacheKey('skillsGap', '${currentSkills.join(",")}_$targetJobTitle');
        if (_memoryCache.containsKey(cacheKey)) {
          debugPrint('🎯 [Skills] Returning cached skills gap analysis');
          return _memoryCache[cacheKey]!;
        }

        final prompt = '''
Analyze the skills gap for someone wanting to become a $targetJobTitle.

Current Skills: ${currentSkills.join(', ')}

Identify:
1. Skills they already have that are relevant
2. Skills they need to learn
3. Priority order for learning
4. Estimated time to close the gap
5. Recommended resources

Return ONLY valid JSON:
{
  "relevantSkills": ["skill1", "skill2"],
  "missingSkills": ["skill1", "skill2"],
  "priorityOrder": ["highest priority skill", "next", "..."],
  "estimatedMonths": number,
  "recommendations": [
    {"skill": "...", "resource": "...", "type": "course|book|project"}
  ],
  "readiness": "percentage 0-100",
  "advice": "Personalized advice paragraph"
}
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        if (text.isEmpty) {
          throw Exception('Empty response from AI');
        }
        final jsonData = _decodeJsonMap(text);
        _memoryCache[cacheKey] = jsonData;
        return jsonData;
      },
    );
  }

  /// Generate content from a custom prompt
  /// Used for AI hints and other custom AI features
  /// Throws exception if AI is not available (NO FALLBACK)
  Future<String> generateContentFromPrompt(String prompt) async {
    await _ensureReady();

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from AI');
      }
      return text;
    } catch (e) {
      debugPrint('❌ Error generating content from prompt: $e');
      _handleQuotaError(e);
      rethrow; // NO FALLBACK
    }
  }

  /// Generate optimized job description for employers
  /// Throws exception if AI is not available
  Future<String> generateJobDescription({
    required String jobTitle,
    required String company,
    required List<String> responsibilities,
    required List<String> requirements,
    required String employmentType,
    String? salaryRange,
    String? companyDescription,
  }) async {
    await _ensureReady();

    try {
      final prompt = '''
${_getCurrencyConversionInstruction()}

Generate a professional, SEO-optimized job description.

Job Title: $jobTitle
Company: $company
${companyDescription != null ? 'About Company: $companyDescription' : ''}
Employment Type: $employmentType
${salaryRange != null ? 'Salary Range: $salaryRange (convert to BWP if in another currency)' : ''}

Key Responsibilities:
${responsibilities.map((r) => '- $r').join('\n')}

Requirements:
${requirements.map((r) => '- $r').join('\n')}

Guidelines:
- Use inclusive language
- Be specific and clear
- Include company culture hints
- Make it engaging and attractive
- Structure with clear sections
- Keep it scannable with bullet points
- All salary/compensation amounts must be in BWP only (convert from other currencies if needed)

Return the complete job description text, formatted with markdown.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from AI');
      }
      return text;
    } catch (e) {
      debugPrint('❌ Error generating job description: $e');
      _handleQuotaError(e);
      rethrow;
    }
  }

  /// Generate a career roadmap based on CV and target role
  /// STANDARDIZED PATTERN: Uses local Gemini with structure validation
  /// Throws exception if AI is not available
  Future<Map<String, dynamic>> generateCareerRoadmap({
    required Map<String, dynamic> userProfile,
    required String targetRole,
    String? targetIndustry,
  }) async {
    return _aiOperation(
      operationName: 'generateCareerRoadmap',
      operation: () async {
        final cacheKey = _generateCacheKey(
            'roadmap', '${jsonEncode(userProfile)}_$targetRole');
        
        // Check cache first
        if (_memoryCache.containsKey(cacheKey)) {
          debugPrint('📋 [Roadmap] Returning cached career roadmap');
          return _memoryCache[cacheKey]!;
        }

        final prompt = '''
${_getCurrencyConversionInstruction()}

Generate a career roadmap for a user whose profile is:
${jsonEncode(userProfile)}

Their target role is: $targetRole
${targetIndustry != null ? "Target Industry: $targetIndustry" : ""}

In the "salaryProgression" field, all amounts must be in BWP only (e.g., "Entry level: P 30,000 - P 50,000, Mid-level: P 60,000 - P 90,000").
If you reference international salary data, convert it to BWP using the exchange rates provided above.

Return ONLY valid JSON with this structure (no markdown code fences):
{
  "totalEstimatedTime": "string (e.g., 12 months)",
  "milestones": [
    {
      "title": "string",
      "description": "string",
      "skillsToLearn": ["skill1", "skill2"],
      "estimatedDuration": "string",
      "recommendedResources": ["resource1", "link/text"]
    }
  ],
  "marketOutlook": "string describing the demand for $targetRole",
  "salaryProgression": "string describing typical growth (all amounts in BWP only)"
}
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        
        if (text.isEmpty) {
          throw Exception('Empty response from Gemini');
        }

        // Parse JSON
        final jsonData = _decodeJsonMap(text);

        // ✅ VALIDATE STRUCTURE - prevents crashes from malformed responses
        if (!jsonData.containsKey('milestones')) {
          throw Exception(
              'Invalid roadmap structure: missing "milestones" field. Got keys: ${jsonData.keys.join(", ")}');
        }

        final milestones = jsonData['milestones'];
        if (milestones is! List) {
          throw Exception(
              'Invalid roadmap: "milestones" must be an array, got ${milestones.runtimeType}');
        }

        if (milestones.isEmpty) {
          throw Exception('Invalid roadmap: "milestones" array is empty');
        }

        // Validate each milestone has required fields
        for (int i = 0; i < milestones.length; i++) {
          final milestone = milestones[i];
          if (milestone is! Map<String, dynamic>) {
            throw Exception('Invalid milestone at index $i: not a map');
          }
          
          if (!milestone.containsKey('title') ||
              !milestone.containsKey('description')) {
            throw Exception(
                'Invalid milestone at index $i: missing title or description');
          }
        }

        // Cache validated result
        _memoryCache[cacheKey] = jsonData;
        debugPrint('✅ [Roadmap] Generated roadmap with ${milestones.length} milestones');
        return jsonData;
      },
    );
  }

  /// Clean JSON response from Gemini (removes markdown code blocks)

  /// Parse raw CV text into a structured builder model
  /// STANDARDIZED PATTERN: Uses local Gemini with fresh API keys
  /// Throws exception if AI is not available
  Future<Map<String, dynamic>> parseCVForBuilder(String cvText) async {
    return _aiOperation(
      operationName: 'parseCVForBuilder',
      operation: () async {
        final cacheKey = _generateCacheKey('parseCVBuilder', cvText);
        if (_memoryCache.containsKey(cacheKey)) {
          debugPrint('📄 [Parse] Returning cached CV parse result');
          return _memoryCache[cacheKey]!;
        }

        final prompt = '''
Analyze this CV text and return a JSON object matching this structure exactly.
Use "null" for missing fields. Dates should be in YYYY-MM-DD format if possible, or YYYY.

{
  "personal_info": {
    "full_name": "string or null",
    "email": "string or null",
    "phone": "string or null",
    "address": "string or null",
    "linkedin": "string or null",
    "portfolio": "string or null",
    "professional_title": "string or null (e.g. Senior Developer)"
  },
  "education": [
    {
      "institution": "string",
      "degree": "string",
      "field_of_study": "string",
      "start_date": "string (YYYY-MM-DD)",
      "end_date": "string (YYYY-MM-DD or Present)",
      "description": "string",
      "education_type": "Formal"
    }
  ],
  "experience": [
    {
      "company": "string",
      "position": "string",
      "start_date": "string (YYYY-MM-DD)",
      "end_date": "string (YYYY-MM-DD or Present)",
      "is_current": boolean,
      "description": "string"
    }
  ],
  "skills": ["string", "string"],
  "languages": [
    { "name": "string", "proficiency": "Intermediate" }
  ],
  "certifications": [
    { "name": "string", "issuer": "string", "issue_date": "string" }
  ],
  "projects": [
    { "name": "string", "description": "string", "url": "string", "technologies": ["string"] }
  ],
  "summary": "string"
}

CV Text:
$cvText
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        if (text.isEmpty) {
          throw Exception('Empty response from AI');
        }

        final jsonData = _decodeJsonMap(text);
        _memoryCache[cacheKey] = jsonData;
        return jsonData;
      },
    );
  }

  /// Generate plain text using Gemini (for hints, descriptions, etc.)
  /// Returns raw text without JSON parsing
  /// Used for generating field-level hints and contextual descriptions
  Future<String> generateText({
    required String prompt,
    int maxTokens = 200,
  }) async {
    return _aiOperation<String>(
      operationName: 'generateText',
      operation: () async {
        await _ensureReady();

        final cacheKey = _generateCacheKey('generateText', prompt);
        if (_memoryCache.containsKey(cacheKey)) {
          debugPrint('✏️ [Text Generate] Returning cached text');
          return _memoryCache[cacheKey]!['text'] as String;
        }

        final response = await _model!.generateContent(
          [Content.text(prompt)],
          generationConfig: GenerationConfig(maxOutputTokens: maxTokens),
        );

        final text = response.text?.trim() ?? '';
        if (text.isEmpty) {
          throw Exception('Empty response from AI text generation');
        }

        _memoryCache[cacheKey] = {'text': text};
        return text;
      },
    );
  }}