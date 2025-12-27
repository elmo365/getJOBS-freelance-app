import 'package:flutter_test/flutter_test.dart';
import 'package:freelance_app/services/validation/input_validators.dart';

void main() {
  group('InputValidators', () {
    // Email validation tests
    group('validateEmail', () {
      test('accepts valid email', () {
        expect(InputValidators.validateEmail('test@example.com'), isNull);
      });

      test('accepts valid email with multiple subdomains', () {
        expect(InputValidators.validateEmail('user@mail.example.co.uk'), isNull);
      });

      test('accepts email with numbers and special chars', () {
        expect(
          InputValidators.validateEmail('user+tag@example123.com'),
          isNull,
        );
      });

      test('rejects empty email', () {
        expect(InputValidators.validateEmail(''), isNotNull);
      });

      test('rejects null email', () {
        expect(InputValidators.validateEmail(null), isNotNull);
      });

      test('rejects email without @', () {
        expect(InputValidators.validateEmail('invalidemail.com'), isNotNull);
      });

      test('rejects email without domain', () {
        expect(InputValidators.validateEmail('user@'), isNotNull);
      });

      test('rejects email with spaces', () {
        expect(
          InputValidators.validateEmail('user @example.com'),
          isNotNull,
        );
      });
    });

    // Password validation tests
    group('validatePassword', () {
      test('accepts strong password', () {
        expect(
          InputValidators.validatePassword('StrongPass123!'),
          isNull,
        );
      });

      test('rejects password less than 8 characters', () {
        expect(
          InputValidators.validatePassword('Short1!'),
          contains('8 characters'),
        );
      });

      test('rejects password without uppercase', () {
        expect(
          InputValidators.validatePassword('password123!'),
          contains('uppercase'),
        );
      });

      test('rejects password without lowercase', () {
        expect(
          InputValidators.validatePassword('PASSWORD123!'),
          contains('lowercase'),
        );
      });

      test('rejects password without number', () {
        expect(
          InputValidators.validatePassword('PasswordSpecial!'),
          contains('number'),
        );
      });

      test('rejects password without special character', () {
        expect(
          InputValidators.validatePassword('Password123'),
          contains('special character'),
        );
      });

      test('rejects empty password', () {
        expect(InputValidators.validatePassword(''), isNotNull);
      });

      test('rejects null password', () {
        expect(InputValidators.validatePassword(null), isNotNull);
      });
    });

    // Phone validation tests
    group('validatePhone', () {
      test('accepts valid phone 10 digits', () {
        expect(InputValidators.validatePhone('1234567890'), isNull);
      });

      test('accepts valid phone 7 digits', () {
        expect(InputValidators.validatePhone('1234567'), isNull);
      });

      test('accepts valid phone with formatting', () {
        expect(InputValidators.validatePhone('(123) 456-7890'), isNull);
      });

      test('rejects phone less than 7 digits', () {
        expect(
          InputValidators.validatePhone('123456'),
          isNotNull,
        );
      });

      test('rejects phone more than 15 digits', () {
        expect(
          InputValidators.validatePhone('12345678901234567'),
          isNotNull,
        );
      });

      test('rejects empty phone', () {
        expect(InputValidators.validatePhone(''), isNotNull);
      });

      test('rejects null phone', () {
        expect(InputValidators.validatePhone(null), isNotNull);
      });

      test('rejects phone with letters', () {
        expect(
          InputValidators.validatePhone('123456abc90'),
          isNotNull,
        );
      });
    });

    // Job deadline validation tests
    group('validateJobDeadline', () {
      test('rejects null deadline', () {
        expect(
          InputValidators.validateJobDeadline(null),
          isNotNull,
        );
      });

      test('rejects deadline for today', () {
        final today = DateTime.now();
        expect(
          InputValidators.validateJobDeadline(today),
          isNotNull,
        );
      });

      test('rejects deadline for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(
          InputValidators.validateJobDeadline(yesterday),
          isNotNull,
        );
      });

      test('accepts deadline for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(
          InputValidators.validateJobDeadline(tomorrow),
          isNull,
        );
      });

      test('accepts deadline for next month', () {
        final nextMonth = DateTime.now().add(const Duration(days: 30));
        expect(
          InputValidators.validateJobDeadline(nextMonth),
          isNull,
        );
      });
    });

    // Salary validation tests
    group('validateSalary', () {
      test('accepts valid salary 50000', () {
        expect(InputValidators.validateSalary('50000'), isNull);
      });

      test('accepts minimum salary 0', () {
        expect(InputValidators.validateSalary('0'), isNull);
      });

      test('accepts maximum salary 999999', () {
        expect(InputValidators.validateSalary('999999'), isNull);
      });

      test('rejects negative salary', () {
        expect(
          InputValidators.validateSalary('-100'),
          contains('negative'),
        );
      });

      test('rejects salary exceeding maximum', () {
        expect(
          InputValidators.validateSalary('1000000'),
          contains('exceed'),
        );
      });

      test('rejects non-numeric salary', () {
        expect(
          InputValidators.validateSalary('abc'),
          isNotNull,
        );
      });

      test('rejects empty salary', () {
        expect(InputValidators.validateSalary(''), isNotNull);
      });

      test('rejects null salary', () {
        expect(InputValidators.validateSalary(null), isNotNull);
      });
    });

    // Currency validation tests
    group('validateCurrency', () {
      test('accepts valid currency 100.50', () {
        expect(InputValidators.validateCurrency('100.50'), isNull);
      });

      test('accepts currency without decimals', () {
        expect(InputValidators.validateCurrency('100'), isNull);
      });

      test('accepts minimum currency 0.01', () {
        expect(InputValidators.validateCurrency('0.01'), isNull);
      });

      test('accepts maximum currency 999999.99', () {
        expect(InputValidators.validateCurrency('999999.99'), isNull);
      });

      test('rejects negative currency', () {
        expect(
          InputValidators.validateCurrency('-50.00'),
          contains('negative'),
        );
      });

      test('rejects currency exceeding maximum', () {
        expect(
          InputValidators.validateCurrency('1000000.00'),
          contains('exceed'),
        );
      });

      test('rejects currency with more than 2 decimals', () {
        expect(
          InputValidators.validateCurrency('100.505'),
          contains('2 decimal'),
        );
      });

      test('rejects empty currency', () {
        expect(InputValidators.validateCurrency(''), isNotNull);
      });

      test('rejects null currency', () {
        expect(InputValidators.validateCurrency(null), isNotNull);
      });
    });

    // URL validation tests
    group('validateURL', () {
      test('accepts valid HTTPS URL', () {
        expect(
          InputValidators.validateURL('https://example.com'),
          isNull,
        );
      });

      test('rejects HTTP URL (must be HTTPS)', () {
        expect(
          InputValidators.validateURL('http://example.com'),
          isNotNull,
        );
      });

      test('accepts URL with www', () {
        expect(
          InputValidators.validateURL('https://www.example.com'),
          isNull,
        );
      });

      test('accepts URL with path', () {
        expect(
          InputValidators.validateURL('https://example.com/path/to/page'),
          isNull,
        );
      });

      test('rejects empty URL', () {
        expect(InputValidators.validateURL(''), isNotNull);
      });

      test('rejects null URL', () {
        expect(InputValidators.validateURL(null), isNotNull);
      });

      test('accepts URL from whitelisted domain', () {
        expect(
          InputValidators.validateURL(
            'https://zoom.us/meeting/123',
            whitelistedDomains: ['zoom.us', 'meet.google.com'],
          ),
          isNull,
        );
      });

      test('rejects URL not in whitelist', () {
        expect(
          InputValidators.validateURL(
            'https://random-site.com',
            whitelistedDomains: ['zoom.us', 'meet.google.com'],
          ),
          isNotNull,
        );
      });
    });

    // Meeting link validation tests
    group('validateMeetingLink', () {
      test('accepts valid Zoom link', () {
        expect(
          InputValidators.validateMeetingLink('https://zoom.us/j/123456'),
          isNull,
        );
      });

      test('accepts valid Google Meet link', () {
        expect(
          InputValidators.validateMeetingLink(
            'https://meet.google.com/abc-defg-hij',
          ),
          isNull,
        );
      });

      test('accepts valid Teams link', () {
        expect(
          InputValidators.validateMeetingLink(
            'https://teams.microsoft.com/l/meetup-join/123',
          ),
          isNull,
        );
      });

      test('rejects random URL not in platform list', () {
        expect(
          InputValidators.validateMeetingLink('https://random-site.com'),
          isNotNull,
        );
      });

      test('rejects empty link', () {
        expect(InputValidators.validateMeetingLink(''), isNotNull);
      });

      test('rejects null link', () {
        expect(InputValidators.validateMeetingLink(null), isNotNull);
      });
    });

    // Date range validation tests
    group('validateDateRange', () {
      test('accepts valid date range', () {
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);
        expect(
          InputValidators.validateDateRange(
            start,
            end,
            startLabel: 'Start',
            endLabel: 'End',
          ),
          isNull,
        );
      });

      test('rejects when start is after end', () {
        final start = DateTime(2025, 1, 31);
        final end = DateTime(2025, 1, 1);
        expect(
          InputValidators.validateDateRange(
            start,
            end,
            startLabel: 'Start',
            endLabel: 'End',
          ),
          isNotNull,
        );
      });

      test('rejects null start date', () {
        final end = DateTime(2025, 1, 31);
        expect(
          InputValidators.validateDateRange(
            null,
            end,
            startLabel: 'Start',
            endLabel: 'End',
          ),
          isNotNull,
        );
      });

      test('rejects null end date', () {
        final start = DateTime(2025, 1, 1);
        expect(
          InputValidators.validateDateRange(
            start,
            null,
            startLabel: 'Start',
            endLabel: 'End',
          ),
          isNotNull,
        );
      });
    });

    // Search sanitization tests
    group('sanitizeSearchInput', () {
      test('removes dangerous characters', () {
        final result =
            InputValidators.sanitizeSearchInput('<script>alert("xss")</script>');
        expect(result, equals('scriptalertxssscript'));
      });

      test('removes quotes and special chars', () {
        final result = InputValidators.sanitizeSearchInput("'; DROP TABLE--");
        expect(result, isNotNull);
        expect(result.contains(';'), isFalse);
        expect(result.contains('"'), isFalse);
      });

      test('enforces max length 100', () {
        final longString = 'a' * 200;
        final result = InputValidators.sanitizeSearchInput(longString);
        expect(result.length, lessThanOrEqualTo(100));
      });

      test('trims whitespace', () {
        final result = InputValidators.sanitizeSearchInput('  search term  ');
        expect(result, equals('search term'));
      });
    });

    // Job title validation tests
    group('validateJobTitle', () {
      test('accepts valid job title', () {
        expect(
          InputValidators.validateJobTitle('Senior Flutter Developer'),
          isNull,
        );
      });

      test('rejects title less than 3 characters', () {
        expect(
          InputValidators.validateJobTitle('Dev'),
          isNotNull,
        );
      });

      test('rejects title exceeding 100 characters', () {
        expect(
          InputValidators.validateJobTitle('a' * 101),
          isNotNull,
        );
      });

      test('rejects empty title', () {
        expect(InputValidators.validateJobTitle(''), isNotNull);
      });

      test('rejects null title', () {
        expect(InputValidators.validateJobTitle(null), isNotNull);
      });
    });

    // Name validation tests
    group('validateName', () {
      test('accepts valid name with letters', () {
        expect(InputValidators.validateName('John Doe'), isNull);
      });

      test('accepts name with apostrophe', () {
        expect(InputValidators.validateName("O'Brien"), isNull);
      });

      test('accepts name with hyphen', () {
        expect(InputValidators.validateName('Mary-Jane'), isNull);
      });

      test('rejects name with numbers', () {
        expect(InputValidators.validateName('John123'), isNotNull);
      });

      test('rejects name with special characters', () {
        expect(InputValidators.validateName('John@Doe'), isNotNull);
      });

      test('rejects empty name', () {
        expect(InputValidators.validateName(''), isNotNull);
      });

      test('rejects null name', () {
        expect(InputValidators.validateName(null), isNotNull);
      });
    });
  });
}
