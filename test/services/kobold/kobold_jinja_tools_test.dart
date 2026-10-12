// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late StorageService storage;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('fpai-jinja-tools-');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return call.method == 'getApplicationDocumentsDirectory'
              ? root.path
              : null;
        });
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.initialized;
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<Map<String, dynamic>> stage(String name, {String? preset}) async {
    final staged = await stageKoboldRole(
      storage: storage,
      executablePath: '',
      name: name,
      modelPath: '',
      kcppsPath: preset,
      mmprojPath: null,
      gpuLayers: 0,
      contextSize: 2048,
      useVulkan: false,
      useCublas: false,
      useMetal: false,
      useRocm: false,
    );
    return (jsonDecode(await File(staged.path).readAsString()) as Map)
        .cast<String, dynamic>();
  }

  test('all staged roles preserve Jinja for tool requests', () async {
    for (final name in [
      kStagedChatConfig,
      'fpai-helper.kcpps',
      'fpai-story.kcpps',
    ]) {
      final config = await stage(name);
      expect(config['jinja'], isTrue);
      expect(config['jinja_tools'], isTrue, reason: name);
    }
  });

  test('tool templating overrides a preset without editing it', () async {
    for (final choice in [null, false, true]) {
      final preset = File('${root.path}/preset.kcpps');
      final original = jsonEncode({
        'contextsize': 2048,
        'jinja_tools': ?choice,
      });
      await preset.writeAsString(original);
      final config = await stage(kStagedChatConfig, preset: preset.path);
      expect(config['jinja_tools'], isTrue);
      expect(await preset.readAsString(), original);
      expect(config['contextsize'], 2048);
    }
  });
}
