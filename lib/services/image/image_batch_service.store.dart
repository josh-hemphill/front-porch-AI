// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'image_batch_service.dart';

extension _ImageBatchStore on ImageBatchService {
  Directory get _folder => _batchFolder;
  File _file(String name) {
    if (!RegExp(r'^[a-f0-9-]+\.png$').hasMatch(name)) {
      throw FormatException('Invalid batch image name');
    }
    return File(p.join(_folder.path, name));
  }

  Future<void> _load() async {
    await storage.initialized;
    _batchFolder = Directory(p.join(storage.rootPath!, 'ImageBatches'));
    await _folder.create(recursive: true);
    final manifest = File(p.join(_folder.path, 'queue.json'));
    if (!await manifest.exists()) return;
    final data =
        jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
    if (data['version'] != 1) {
      throw StateError('Unsupported image batch format.');
    }
    for (final value in data['jobs'] as List) {
      final job = ImageBatchJob(Map<String, dynamic>.from(value as Map));
      if (job.state == 'running') {
        job.data.addAll({
          'state': 'interrupted',
          'error':
              'The app closed during this request. Check the backend before preparing another pass.',
        });
      }
      _jobs.add(job);
    }
    _changed();
  }

  Future<void> _persist() {
    final content = jsonEncode({
      'version': 1,
      'jobs': [for (final j in _jobs) j.data],
    });
    final next = _writes.then((_) async {
      final temp = File(p.join(_folder.path, 'queue.json.tmp'));
      await temp.writeAsString(content, flush: true);
      await temp.rename(p.join(_folder.path, 'queue.json'));
    });
    _writes = next.then<void>(
      (_) {},
      onError: (Object e) {
        error = 'Could not save the image queue: $e';
        pauseRequested = true;
        _changed();
      },
    );
    _changed();
    return next;
  }
}
