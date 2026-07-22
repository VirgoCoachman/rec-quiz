import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_coverage.dart';

void main() {
  group('parseLcov', () {
    test('aggregates line coverage across source records', () {
      const lcov = '''
SF:lib/features/quiz/quiz.dart
LF:60
LH:40
end_of_record
SF:lib/features/settings/settings.dart
LF:40
LH:25
end_of_record
''';

      final summary = parseLcov(lcov);

      expect(summary.linesFound, 100);
      expect(summary.linesHit, 65);
      expect(summary.percentage, 65);
    });

    test('excludes generated localization files', () {
      const lcov = '''
SF:lib/features/quiz/quiz.dart
LF:100
LH:65
end_of_record
SF:lib/l10n/app_localizations.dart
LF:100
LH:0
end_of_record
SF:lib/l10n/app_localizations_fr.dart
LF:100
LH:0
end_of_record
''';

      final summary = parseLcov(lcov);

      expect(summary.linesFound, 100);
      expect(summary.linesHit, 65);
      expect(summary.percentage, 65);
    });

    test('accepts coverage exactly at the threshold', () {
      const lcov = '''
SF:lib/app.dart
LF:100
LH:65
end_of_record
''';

      expect(parseLcov(lcov).meetsThreshold(65), isTrue);
    });

    test('rejects coverage below the threshold', () {
      const lcov = '''
SF:lib/app.dart
LF:100
LH:64
end_of_record
''';

      expect(parseLcov(lcov).meetsThreshold(65), isFalse);
    });

    test('rejects empty coverage data', () {
      expect(() => parseLcov(''), throwsFormatException);
    });

    test('rejects malformed coverage values', () {
      const lcov = '''
SF:lib/app.dart
LF:not-a-number
LH:10
end_of_record
''';

      expect(() => parseLcov(lcov), throwsFormatException);
    });

    test('rejects coverage without coverable lines', () {
      const lcov = '''
SF:lib/app.dart
LF:0
LH:0
end_of_record
''';

      expect(() => parseLcov(lcov), throwsFormatException);
    });

    test('rejects hit line counts greater than found line counts', () {
      const lcov = '''
SF:lib/app.dart
LF:10
LH:11
end_of_record
''';

      expect(() => parseLcov(lcov), throwsFormatException);
    });
  });
}
