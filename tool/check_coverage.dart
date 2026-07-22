import 'dart:io';

final class CoverageSummary {
  const CoverageSummary({required this.linesFound, required this.linesHit});

  final int linesFound;
  final int linesHit;

  double get percentage => linesHit * 100 / linesFound;

  bool meetsThreshold(double threshold) => percentage >= threshold;
}

CoverageSummary parseLcov(String source) {
  var linesFound = 0;
  var linesHit = 0;
  var hasIncludedSource = false;
  var hasFoundMetric = false;
  var hasHitMetric = false;
  String? currentSource;
  var excludesCurrentSource = false;

  for (final rawLine in source.split('\n')) {
    final line = rawLine.trim();

    if (line.startsWith('SF:')) {
      currentSource = line.substring(3).trim();
      if (currentSource.isEmpty) {
        throw const FormatException('LCOV contains an empty source path.');
      }

      excludesCurrentSource = _isGeneratedLocalization(currentSource);
      hasIncludedSource |= !excludesCurrentSource;
      continue;
    }

    if (line == 'end_of_record') {
      currentSource = null;
      excludesCurrentSource = false;
      continue;
    }

    if (!line.startsWith('LF:') && !line.startsWith('LH:')) {
      continue;
    }

    if (currentSource == null) {
      throw FormatException(
        'LCOV metric appears outside a source record: $line',
      );
    }

    if (excludesCurrentSource) {
      continue;
    }

    final value = int.tryParse(line.substring(3).trim());
    if (value == null || value < 0) {
      throw FormatException('Invalid LCOV metric: $line');
    }

    if (line.startsWith('LF:')) {
      linesFound += value;
      hasFoundMetric = true;
    } else {
      linesHit += value;
      hasHitMetric = true;
    }
  }

  if (!hasIncludedSource || !hasFoundMetric || !hasHitMetric) {
    throw const FormatException(
      'LCOV contains no complete coverage data for included source files.',
    );
  }
  if (linesFound == 0) {
    throw const FormatException('LCOV contains no coverable lines.');
  }
  if (linesHit > linesFound) {
    throw FormatException(
      'LCOV reports more hit lines ($linesHit) than found lines ($linesFound).',
    );
  }

  return CoverageSummary(linesFound: linesFound, linesHit: linesHit);
}

bool _isGeneratedLocalization(String sourcePath) {
  final normalizedPath = sourcePath.replaceAll('\\', '/');
  return RegExp(
    r'(?:^|/)app_localizations(?:_[^/]+)?\.dart$',
  ).hasMatch(normalizedPath);
}

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    stderr.writeln(
      'Usage: fvm dart run tool/check_coverage.dart '
      '<lcov-file> [minimum-percentage]',
    );
    exitCode = 64;
    return;
  }

  final threshold = arguments.length == 2
      ? double.tryParse(arguments[1])
      : 65.0;
  if (threshold == null || threshold < 0 || threshold > 100) {
    stderr.writeln('Coverage threshold must be a number from 0 to 100.');
    exitCode = 64;
    return;
  }

  final coverageFile = File(arguments.first);
  if (!coverageFile.existsSync()) {
    stderr.writeln('Coverage file not found: ${coverageFile.path}');
    exitCode = 66;
    return;
  }

  try {
    final summary = parseLcov(coverageFile.readAsStringSync());
    stdout.writeln(
      'Coverage: ${summary.linesHit}/${summary.linesFound} lines '
      '(${summary.percentage.toStringAsFixed(2)}%), '
      'required ${threshold.toStringAsFixed(2)}%.',
    );

    if (!summary.meetsThreshold(threshold)) {
      stderr.writeln('Coverage is below the required threshold.');
      exitCode = 1;
    }
  } on FormatException catch (error) {
    stderr.writeln('Invalid coverage data: ${error.message}');
    exitCode = 65;
  } on FileSystemException catch (error) {
    stderr.writeln('Unable to read coverage file: ${error.message}');
    exitCode = 66;
  }
}
