class InputValidators {
  /// Email validation using RFC 5322 compliant pattern
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Password validation requiring 8+ characters with complexity
  /// Requirements:
  /// - At least 8 characters
  /// - At least one uppercase letter (A-Z)
  /// - At least one lowercase letter (a-z)
  /// - At least one number (0-9)
  /// - At least one special character (!@#$%^&*)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter (A-Z)';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter (a-z)';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number (0-9)';
    }

    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain a special character (!@#\$%^&*)';
    }

    return null;
  }

  /// Phone number validation (7-15 digits)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^\d{7,15}$');

    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\+\(\)]'), ''))) {
      return 'Phone number must be 7-15 digits';
    }

    return null;
  }

  /// Job deadline validation - must be at least tomorrow
  static String? validateJobDeadline(DateTime? selectedDate) {
    if (selectedDate == null) {
      return 'Deadline date is required';
    }

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final deadlineStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final selectedDateOnly = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (selectedDateOnly.isBefore(deadlineStart)) {
      return 'Deadline must be at least tomorrow';
    }

    return null;
  }

  /// Salary validation - range 0 to 999,999
  static String? validateSalary(String? value) {
    if (value == null || value.isEmpty) {
      return 'Salary is required';
    }

    final salary = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));

    if (salary == null) {
      return 'Salary must be a valid number';
    }

    if (salary < 0) {
      return 'Salary cannot be negative';
    }

    if (salary > 999999) {
      return 'Salary cannot exceed 999,999';
    }

    return null;
  }

  /// Currency validation - range 0.00 to 999,999.99
  static String? validateCurrency(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(
      value.replaceAll(RegExp(r'[^\d\.]'), ''),
    );

    if (amount == null) {
      return 'Amount must be a valid number';
    }

    if (amount < 0) {
      return 'Amount cannot be negative';
    }

    if (amount > 999999.99) {
      return 'Amount cannot exceed 999,999.99';
    }

    // Check decimal places
    final parts = value.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'Amount can have maximum 2 decimal places';
    }

    return null;
  }

  /// Integer range validation
  static String? validateIntRange(
    String? value, {
    required int min,
    required int max,
    required String fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final intValue = int.tryParse(value);

    if (intValue == null) {
      return '$fieldName must be a valid number';
    }

    if (intValue < min) {
      return '$fieldName must be at least $min';
    }

    if (intValue > max) {
      return '$fieldName cannot exceed $max';
    }

    return null;
  }

  /// Text length validation
  static String? validateTextLength(
    String? value, {
    required int minLength,
    required int maxLength,
    required String fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }

    return null;
  }

  /// URL validation - https only with optional domain whitelist
  static String? validateURL(
    String? value, {
    List<String>? whitelistedDomains,
  }) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    final urlRegex = RegExp(
      r'^https:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid HTTPS URL';
    }

    if (whitelistedDomains != null && whitelistedDomains.isNotEmpty) {
      final isAllowed = whitelistedDomains.any((domain) {
        return value.contains(domain);
      });

      if (!isAllowed) {
        return 'URL domain is not allowed. Supported: ${whitelistedDomains.join(", ")}';
      }
    }

    return null;
  }

  /// Meeting link validation - whitelist of supported platforms
  static String? validateMeetingLink(String? value) {
    if (value == null || value.isEmpty) {
      return 'Meeting link is required';
    }

    final whitelistedDomains = [
      'zoom.us',
      'zoom.com',
      'meet.google.com',
      'teams.microsoft.com',
      'meet.jit.si',
    ];

    return validateURL(value, whitelistedDomains: whitelistedDomains);
  }

  /// Date range validation - ensure start date is before end date
  static String? validateDateRange(
    DateTime? startDate,
    DateTime? endDate, {
    required String startLabel,
    required String endLabel,
  }) {
    if (startDate == null) {
      return '$startLabel is required';
    }

    if (endDate == null) {
      return '$endLabel is required';
    }

    if (startDate.isAfter(endDate)) {
      return '$endLabel must be after $startLabel';
    }

    return null;
  }

  /// Search input sanitization - removes dangerous characters
  /// and enforces max length
  static String sanitizeSearchInput(String input) {
    final sanitized = input
        .replaceAll(RegExp(r'[<>&]'), '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    return sanitized.substring(0, sanitized.length > 100 ? 100 : sanitized.length);
  }

  /// Generic required field validation
  static String? validateRequired(
    String? value, {
    required String fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  /// Job title validation
  static String? validateJobTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Job title is required';
    }

    if (value.length < 3) {
      return 'Job title must be at least 3 characters';
    }

    if (value.length > 100) {
      return 'Job title cannot exceed 100 characters';
    }

    return null;
  }

  /// Job description validation
  static String? validateJobDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Job description is required';
    }

    if (value.length < 20) {
      return 'Job description must be at least 20 characters';
    }

    if (value.length > 5000) {
      return 'Job description cannot exceed 5000 characters';
    }

    return null;
  }

  /// Company name validation
  static String? validateCompanyName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Company name is required';
    }

    if (value.length < 2) {
      return 'Company name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Company name cannot exceed 100 characters';
    }

    return null;
  }

  /// Location/Address validation
  static String? validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Location is required';
    }

    if (value.length < 3) {
      return 'Location must be at least 3 characters';
    }

    if (value.length > 200) {
      return 'Location cannot exceed 200 characters';
    }

    return null;
  }

  /// Budget validation - monetary amount with range
  static String? validateBudget(String? value) {
    if (value == null || value.isEmpty) {
      return 'Budget is required';
    }

    final amount = double.tryParse(
      value.replaceAll(RegExp(r'[^\d\.]'), ''),
    );

    if (amount == null) {
      return 'Budget must be a valid number';
    }

    if (amount <= 0) {
      return 'Budget must be greater than 0';
    }

    if (amount > 999999999) {
      return 'Budget cannot exceed 999,999,999';
    }

    return null;
  }

  /// Price validation - for gigs and services (0 - 99,999)
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }

    final amount = double.tryParse(
      value.replaceAll(RegExp(r'[^\d\.]'), ''),
    );

    if (amount == null) {
      return 'Price must be a valid number';
    }

    if (amount <= 0) {
      return 'Price must be greater than 0';
    }

    if (amount > 99999) {
      return 'Price cannot exceed 99,999';
    }

    return null;
  }

  /// Wallet amount validation
  static String? validateWalletAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(
      value.replaceAll(RegExp(r'[^\d\.]'), ''),
    );

    if (amount == null) {
      return 'Amount must be a valid number';
    }

    if (amount < 0.01) {
      return 'Minimum amount is 0.01';
    }

    if (amount > 99999.99) {
      return 'Maximum amount is 99,999.99';
    }

    return null;
  }

  /// Name validation - first or last name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name cannot exceed 50 characters';
    }

    // Check for only letters and spaces
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Rating validation (0-5 stars)
  static String? validateRating(String? value) {
    if (value == null || value.isEmpty) {
      return 'Rating is required';
    }

    final rating = double.tryParse(value);

    if (rating == null) {
      return 'Rating must be a valid number';
    }

    if (rating < 0 || rating > 5) {
      return 'Rating must be between 0 and 5';
    }

    return null;
  }
}
