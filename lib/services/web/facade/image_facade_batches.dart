// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'image_facade.dart';

extension ImageFacadeBatches on ImageFacade {
  ImageBatchService get batches => _image.batches;
  Future<void> prepareBatch(Map<String, dynamic> body) async {
    final repo = _characters;
    if (repo == null) throw StateError('Character library unavailable.');
    await batches.prepare(
      repository: repo,
      characterIds: List<String>.from(body['characterIds'] as List),
      kind: body['kind'] as String,
      prompt: body['prompt'] as String? ?? '',
      edit: body['edit'] == true,
      missingOnly: body['missingOnly'] != false,
      denoise: (body['denoise'] as num?)?.toDouble(),
    );
  }

  Future<void> saveBatch() async {
    final repo = _characters;
    if (repo == null) throw StateError('Character library unavailable.');
    await batches.saveKept(repo);
  }
}
