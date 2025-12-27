import 'package:flutter/material.dart';
import 'package:freelance_app/services/config/api_keys_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class AdminAPISettingsScreen extends StatefulWidget {
  const AdminAPISettingsScreen({super.key});

  @override
  State<AdminAPISettingsScreen> createState() => _AdminAPISettingsScreenState();
}

class _AdminAPISettingsScreenState extends State<AdminAPISettingsScreen>
    with ConnectivityAware {
  final _apiKeysService = APIKeysService();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _obscureText = {}; // Track visibility state for each password field
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load keys after frame is built to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKeys();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload keys when screen becomes visible again (e.g., returning from hints)
    if (!_isLoading && _controllers.isEmpty) {
      _loadKeys();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadKeys() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      debugPrint('📥 [API Settings] Starting to load API keys from database...');
      
      // Clear cache to ensure fresh data on first load
      _apiKeysService.clearCache();
      
      // Load keys with timeout
      final keys = await _apiKeysService.getAllKeys()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱️ [API Settings] Timeout loading keys, using defaults');
              return _apiKeysService.getAvailableKeys()
                  .fold<Map<String, String>>({}, (map, keyInfo) {
                final keyName = keyInfo['key'] as String;
                final defaultValue = keyInfo['defaultValue'] as String? ?? '';
                map[keyName] = defaultValue;
                return map;
              });
            },
          );
      
      debugPrint('✅ [API Settings] Loaded ${keys.length} API keys from database');
      
      final availableKeys = _apiKeysService.getAvailableKeys();
      debugPrint('📋 [API Settings] Found ${availableKeys.length} available key configurations');

      // Initialize controllers
      for (final keyInfo in availableKeys) {
        final keyName = keyInfo['key'] as String;
        final type = keyInfo['type'] as String;
        final defaultValue = keyInfo['defaultValue'] as String? ?? '';
        final currentValue = keys[keyName] ?? defaultValue;
        
        debugPrint('🔑 [API Settings] Key: $keyName = ${type == 'password' ? '***' : (currentValue.isEmpty ? '(empty)' : currentValue)}');
        
        _controllers[keyName] = TextEditingController(text: currentValue);
        // Initialize obscure text state for password fields
        if (type == 'password') {
          _obscureText[keyName] = true;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('✅ [API Settings] Settings loaded successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API Settings] Error loading API settings: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        // Show error but still allow user to see/use default values
        SnackbarHelper.showError(
          context, 
          'Failed to load API settings. Using defaults. Error: ${e.toString()}',
        );
        
        // Initialize with defaults if error occurred
        final availableKeys = _apiKeysService.getAvailableKeys();
        for (final keyInfo in availableKeys) {
          final keyName = keyInfo['key'] as String;
          final type = keyInfo['type'] as String;
          final defaultValue = keyInfo['defaultValue'] as String? ?? '';
          
          if (!_controllers.containsKey(keyName)) {
            _controllers[keyName] = TextEditingController(text: defaultValue);
            if (type == 'password') {
              _obscureText[keyName] = true;
            }
          }
        }
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _saveKeys() async {
    if (!await checkConnectivity(context,
        message:
            'Cannot save API settings without internet. Please connect and try again.')) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final keysToSave = <String, String>{};
      for (final entry in _controllers.entries) {
        keysToSave[entry.key] = entry.value.text.trim();
      }

      final success = await _apiKeysService.updateKeys(keysToSave);

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          SnackbarHelper.showSuccess(
              context, 'API settings saved successfully!');
          
          // Clear API keys cache so fresh keys are fetched on next use
          _apiKeysService.clearCache();
          
          _loadKeys();
        } else {
          SnackbarHelper.showError(context, 'Failed to save API settings');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.showError(context, 'Error saving API settings: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableKeys = _apiKeysService.getAvailableKeys();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: botsSuperLightGrey,
        appBar: AppAppBar(
          title: 'API Settings',
          variant: AppBarVariant.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: botsSuperLightGrey,
      resizeToAvoidBottomInset: true, // Critical for keyboard handling
      appBar: AppAppBar(
        title: 'API Settings',
        variant: AppBarVariant.primary,
      ),
      body: SingleChildScrollView(
        padding: AppDesignSystem.paddingL,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title - matching Hints screen style
            Text(
              'API Configuration',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Text(
              'Manage API keys for external services. Keys are stored securely in Firestore and changes take effect immediately.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

            // API Keys List - using elevated cards like Hints screen
            ...availableKeys.map((keyInfo) {
              final keyName = keyInfo['key'] as String;
              final label = keyInfo['label'] as String;
              final description = keyInfo['description'] as String;
              final type = keyInfo['type'] as String;
              final required = keyInfo['required'] as bool? ?? false;
              final helpUrl = keyInfo['helpUrl'] as String?;

              return Padding(
                padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
                child: AppCard(
                  variant: SurfaceVariant.elevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      label,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (required) ...[
                                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colorScheme.error,
                                          borderRadius: AppDesignSystem.borderRadiusS,
                                        ),
                                        child: Text(
                                          'Required',
                                          style: textTheme.labelSmall?.copyWith(color: colorScheme.onError),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                                Text(
                                  description,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (helpUrl != null)
                            IconButton(
                              icon: const Icon(Icons.help_outline),
                              onPressed: () => SnackbarHelper.showInfo(context, 'Help: $helpUrl'),
                              tooltip: 'Get API key',
                            ),
                        ],
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      TextField(
                        controller: _controllers[keyName],
                        obscureText: type == 'password' ? (_obscureText[keyName] ?? true) : false,
                        keyboardType: type == 'email' ? TextInputType.emailAddress : TextInputType.text,
                        scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                        ),
                        decoration: InputDecoration(
                          labelText: label,
                          hintText: 'Enter $label',
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: AppDesignSystem.borderRadiusM,
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppDesignSystem.borderRadiusM,
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppDesignSystem.borderRadiusM,
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          suffixIcon: type == 'password'
                              ? IconButton(
                                  icon: Icon(
                                    (_obscureText[keyName] ?? true)
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText[keyName] = !(_obscureText[keyName] ?? true);
                                    });
                                  },
                                  tooltip: (_obscureText[keyName] ?? true) ? 'Show' : 'Hide',
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

            // Info card - matching Hints screen style
            AppCard(
              variant: SurfaceVariant.standard,
              child: Padding(
                padding: AppDesignSystem.paddingM,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                        Text(
                          'About API Keys',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Text(
                      'API keys enable external service integrations. Keep keys secure and never share them publicly. If a key is compromised, regenerate it immediately from the service provider.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: StandardButton(
                label: _isSaving ? 'Saving...' : 'Save API Settings',
                onPressed: _isSaving ? null : _saveKeys,
                type: StandardButtonType.primary,
                icon: _isSaving ? null : Icons.save,
              ),
            ),

            AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
          ],
        ),
      ),
    );
  }
}

