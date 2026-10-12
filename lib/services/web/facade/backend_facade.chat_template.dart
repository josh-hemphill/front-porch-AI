// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'backend_facade.dart';

extension BackendFacadeChatTemplate on BackendFacade {
  Future<void> saveChatTemplate({
    required String preset,
    String? name,
    String? content,
  }) async {
    if (_storage.backendSettings.activeKcppsPath != preset) {
      throw const FormatException('The selected preset changed. Try again.');
    }
    await saveUploadedKoboldTemplate(
      engineDir: _storage.binDir.path,
      preset: preset,
      name: name,
      content: content,
      stillSelected: () => _storage.backendSettings.activeKcppsPath == preset,
    );
    await _storage.backendSettings.setActiveKcppsPath(preset);
  }
}
