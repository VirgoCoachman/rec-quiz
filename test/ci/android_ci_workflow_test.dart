import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String workflow;

  setUpAll(() {
    workflow = File('.github/workflows/android_ci.yml').readAsStringSync();
  });

  test(
    'runs for pull requests, protected branch pushes, and manual dispatch',
    () {
      expect(workflow, contains('pull_request:'));
      expect(workflow, contains('push:'));
      expect(workflow, contains('workflow_dispatch:'));
      expect(workflow, contains('- develop'));
      expect(workflow, contains('- main'));
      expect(workflow, isNot(contains('pull_request_target:')));
    },
  );

  test('uses least privilege and cancels superseded runs', () {
    expect(workflow, contains('permissions:'));
    expect(workflow, contains('contents: read'));
    expect(workflow, contains('concurrency:'));
    expect(workflow, contains('cancel-in-progress: true'));
  });

  test('pins the Flutter SDK and maintained action majors', () {
    expect(workflow, contains('actions/checkout@v7'));
    expect(workflow, contains('dart-lang/setup-dart@v1'));
    expect(workflow, contains('actions/cache@v6'));
    expect(workflow, contains('actions/upload-artifact@v7'));
    expect(workflow, contains('dart pub global activate fvm 3.2.1'));
    expect(workflow, contains('fvm install 3.35.3'));
  });

  test('executes the complete Android quality gate through FVM', () {
    const commands = <String>[
      'fvm flutter pub get',
      'fvm flutter gen-l10n',
      'fvm dart format --output=none --set-exit-if-changed lib test tool',
      'fvm flutter analyze',
      'fvm flutter test --coverage',
      'fvm dart run tool/check_coverage.dart coverage/lcov.info 65',
      'fvm flutter build apk --debug',
    ];

    for (final command in commands) {
      expect(workflow, contains(command), reason: 'Missing command: $command');
    }

    expect(workflow, isNot(contains('run: flutter ')));
    expect(workflow, isNot(contains('run: dart ')));
  });

  test('uploads the LCOV report and debug APK', () {
    expect(workflow, contains('coverage/lcov.info'));
    expect(workflow, contains('build/app/outputs/flutter-apk/app-debug.apk'));
    expect(workflow, contains('if-no-files-found: error'));
  });
}
