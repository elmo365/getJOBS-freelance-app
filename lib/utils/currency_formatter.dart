import 'package:intl/intl.dart';

/// Currency formatter for Botswana Pula (BWP)
class CurrencyFormatter {
  static const String currencySymbol = 'P';
  static const String currencyCode = 'BWP';
  static const String currencyName = 'Pula';

  /// Format amount as BWP currency
  /// Example: formatBWP(5000) => "P 5,000.00"
  static String formatBWP(dynamic amount, {bool includeDecimals = true}) {
    if (amount == null) return '$currencySymbol 0.00';
    
    double value;
    if (amount is String) {
      // Handle string amounts - try to parse
      value = double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    } else if (amount is int) {
      value = amount.toDouble();
    } else if (amount is double) {
      value = amount;
    } else {
      return '$currencySymbol 0.00';
    }

    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: includeDecimals ? 2 : 0,
      customPattern: includeDecimals ? '#,##0.00' : '#,##0',
    );

    return '$currencySymbol ${formatter.format(value).replaceAll(currencySymbol, '').trim()}';
  }

  /// Format salary range
  /// Example: formatSalaryRange("5000", "10000") => "P 5,000 - P 10,000"
  static String formatSalaryRange(String? minSalary, String? maxSalary) {
    if (minSalary == null || minSalary.isEmpty) {
      if (maxSalary == null || maxSalary.isEmpty) {
        return 'Negotiable';
      }
      return 'Up to ${formatBWP(maxSalary, includeDecimals: false)}';
    }

    if (maxSalary == null || maxSalary.isEmpty || minSalary == maxSalary) {
      return formatBWP(minSalary, includeDecimals: false);
    }

    return '${formatBWP(minSalary, includeDecimals: false)} - ${formatBWP(maxSalary, includeDecimals: false)}';
  }

  /// Parse salary string that may already contain BWP
  /// Handles formats like: "5000", "5000-10000", "P 5,000", "BWP 5000"
  static String parseSalaryString(String? salary) {
    if (salary == null || salary.isEmpty) return 'Negotiable';
    
    // If already formatted, return as is
    if (salary.toLowerCase().contains('negotiable')) return 'Negotiable';
    
    // Remove existing currency symbols and codes
    String cleaned = salary
        .replaceAll(RegExp(r'[Pp](?![a-z])'), '') // Remove P not followed by lowercase
        .replaceAll('BWP', '')
        .replaceAll('Pula', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Check if it's a range (contains dash or "to")
    if (cleaned.contains('-') || cleaned.toLowerCase().contains(' to ')) {
      List<String> parts = cleaned.split(RegExp(r'\s*-\s*|\s+to\s+', caseSensitive: false));
      if (parts.length == 2) {
        return formatSalaryRange(parts[0].trim(), parts[1].trim());
      }
    }

    // Single amount
    return formatBWP(cleaned, includeDecimals: false);
  }

  /// Format with full currency name
  /// Example: formatWithName(5000) => "5,000.00 Botswana Pula (BWP)"
  static String formatWithName(dynamic amount) {
    return '${formatBWP(amount)} Botswana $currencyName ($currencyCode)';
  }
}
