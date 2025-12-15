import 'dart:io';

void main(List<String> args) {
  final flavor = args.isNotEmpty ? args.first.toLowerCase() : 'dev';
  final filePath = _flavorFiles[flavor];

  if (filePath == null) {
    stderr.writeln('Unknown flavor "$flavor". Use one of: ${_flavorFiles.keys.join(', ')}');
    exitCode = 64; // EX_USAGE
    return;
  }

  final file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln('Firebase options file not found: $filePath');
    exitCode = 66; // EX_NOINPUT
    return;
  }

  final summary = _extractSummary(file.readAsStringSync());
  final expectedProject = _expectedProjects[flavor];

  stdout
    ..writeln('Flavor        : $flavor')
    ..writeln(' projectId    : ${summary.projectId}')
    ..writeln(' appId        : ${summary.appId}')
    ..writeln(' iosBundleId  : ${summary.iosBundleId ?? '-'}')
    ..writeln(' apiKey (mask): ${_mask(summary.apiKey)}');

  if (expectedProject != null && summary.projectId != expectedProject) {
    stderr.writeln(
      'WARNING: Expected projectId "$expectedProject" but found "${summary.projectId}".',
    );
    exitCode = 65; // EX_DATAERR
  }
}

const _flavorFiles = {
  'dev': 'lib/firebase_options_dev.dart',
  'staging': 'lib/firebase_options_staging.dart',
  'prod': 'lib/firebase_options_prod.dart',
  'default': 'lib/firebase_options.dart',
};

const _expectedProjects = {
  'dev': 'wegig-dev',
};

class _FirebaseSummary {
  _FirebaseSummary({
    required this.projectId,
    required this.appId,
    required this.apiKey,
    this.iosBundleId,
  });

  final String projectId;
  final String appId;
  final String apiKey;
  final String? iosBundleId;
}

_FirebaseSummary _extractSummary(String contents) {
  String? _match(String field) {
    final regex = RegExp("$field:\\s*'([^']+)'", multiLine: true);
    return regex.firstMatch(contents)?.group(1);
  }

  return _FirebaseSummary(
    projectId: _match('projectId') ?? 'unknown',
    appId: _match('appId') ?? 'unknown',
    apiKey: _match('apiKey') ?? 'unknown',
    iosBundleId: _match('iosBundleId'),
  );
}

String _mask(String value) {
  if (value.isEmpty || value == 'unknown') {
    return '***';
  }
  final visible = value.length <= 6 ? value : value.substring(0, 6);
  return '$visible***';
}
