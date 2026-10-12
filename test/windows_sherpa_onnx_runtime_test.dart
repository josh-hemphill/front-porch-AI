import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final olderRuntime = Platform.environment['FP_TEST_OLD_ORT'];
  final sherpaDirectory = Platform.environment['FP_TEST_SHERPA_DIR'];
  final nativeSkip =
      !Platform.isWindows || olderRuntime == null || sherpaDirectory == null
      ? 'Set FP_TEST_OLD_ORT and FP_TEST_SHERPA_DIR to real Windows DLL fixtures.'
      : false;

  test(
    'rejects an already loaded older runtime before Sherpa binding',
    () async {
      final result = await _run(sherpaDirectory!, preload: olderRuntime);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('REJECTED:'));
      expect(result.stdout, contains('API 28'));
    },
    skip: nativeSkip,
  );

  test('preloads and accepts the bundled matching runtime', () async {
    final result = await _run(sherpaDirectory!, accept: true);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('ACCEPTED'));
  }, skip: nativeSkip);

  test('rejects a missing bundled runtime before loading Sherpa', () async {
    final empty = await Directory.systemTemp.createTemp('fp-missing-ort-');
    try {
      final result = await _run(empty.path);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('REJECTED:'));
      expect(result.stdout, contains('onnxruntime.dll'));
    } finally {
      await empty.delete(recursive: true);
    }
  }, skip: nativeSkip);

  test('rejects an older runtime bundled beside Sherpa', () async {
    final directory = await Directory.systemTemp.createTemp('fp-older-ort-');
    try {
      await File(olderRuntime!).copy('${directory.path}/onnxruntime.dll');
      final result = await _run(directory.path);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('REJECTED:'));
      expect(result.stdout, contains('API 28'));
    } finally {
      await directory.delete(recursive: true);
    }
  }, skip: nativeSkip);
}

Future<ProcessResult> _run(
  String directory, {
  String? preload,
  bool accept = false,
}) async {
  final temporary = await Directory.systemTemp.createTemp('fp-runtime-check-');
  try {
    final script = File('${temporary.path}/probe.dart');
    await script.writeAsString('''
import 'dart:ffi';
import 'dart:io';
import 'package:front_porch_ai/services/sherpa_runtime.dart';
void main(List<String> args) {
  if (args.length > 1) DynamicLibrary.open(args[1]);
  try {
    initSherpaBindings();
    if (args[0] != 'accept') throw Exception('Expected runtime rejection before Sherpa binding');
    print('ACCEPTED');
  } on StateError catch (error) {
    if (args[0] == 'accept') rethrow;
    print('REJECTED: \$error');
  }
}
''');
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final dart =
        Platform.environment['FP_TEST_DART'] ??
        (flutterRoot == null
            ? 'dart'
            : '$flutterRoot/bin/cache/dart-sdk/bin/dart.exe');
    return await Process.run(
      dart,
      [
        '--packages=${File('.dart_tool/package_config.json').absolute.path}',
        script.path,
        accept ? 'accept' : 'reject',
        ?preload,
      ],
      environment: {'FP_SHERPA_LIB': directory},
    );
  } finally {
    await temporary.delete(recursive: true);
  }
}
