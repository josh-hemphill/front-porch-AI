// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/image/image.dart';
import 'package:front_porch_ai/ui/widgets/widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/pages/image_batches/image_batches.dart';
import 'package:front_porch_ai/ui/image_studio/image_studio.dart';

class ImageBatchesPage extends StatefulWidget {
  const ImageBatchesPage({super.key, this.queue});
  final ImageBatchService? queue;
  @override
  State<ImageBatchesPage> createState() => _ImageBatchesPageState();
}

class _ImageBatchesPageState extends State<ImageBatchesPage> {
  final _selected = <String>{};
  final _prompt = TextEditingController();
  String _kind = 'additional';
  String _search = '';
  bool _edit = false;
  bool _missing = true;
  int _tab = 0;
  String? _error;
  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _action(Future<void> Function() action) async {
    if (mounted) setState(() => _error = null);
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = widget.queue ?? context.read<ImageGenService>().batches;
    final repo = context.watch<CharacterRepository>();
    return FutureBuilder<void>(
      future: queue.ready,
      builder: (context, ready) {
        if (ready.hasError) {
          return Center(
            child: Text('Could not load image batches: ${ready.error}'),
          );
        }
        if (ready.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListenableBuilder(
          listenable: queue,
          builder: (context, _) {
            final busy = queue.running || queue.working;
            final waiting = queue.jobs
                .where((j) => j.state == 'waiting')
                .length;
            final kept = queue.jobs
                .where((j) => j.state == 'review' && j.kept)
                .length;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Images'),
                actions: [
                  TextButton(
                    onPressed: queue.working || kept == 0
                        ? null
                        : () async {
                            if (!await confirmImageBatchSave(context, queue)) {
                              return;
                            }
                            await _action(() => queue.saveKept(repo));
                          },
                    child: Text('Save $kept kept'),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          '${queue.jobs.where((j) => ['review', 'saved'].contains(j.state)).length} finished · $waiting waiting',
                        ),
                        FilledButton(
                          onPressed: busy || waiting == 0
                              ? null
                              : () => unawaited(_action(queue.run)),
                          child: Text('Start $waiting images'),
                        ),
                        OutlinedButton(
                          onPressed: queue.running ? queue.pause : null,
                          child: Text(
                            queue.pauseRequested
                                ? 'Pausing after current image…'
                                : 'Pause after current image',
                          ),
                        ),
                        const Text('Runs while the app remains open.'),
                      ],
                    ),
                  ),
                  if (_error ?? queue.error case final String error)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        error,
                        style: TextStyle(color: AppColors.textPrimary(context)),
                      ),
                    ),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Prepare')),
                      ButtonSegment(value: 1, label: Text('Queue')),
                      ButtonSegment(value: 2, label: Text('Review')),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (s) => setState(() => _tab = s.first),
                  ),
                  Expanded(
                    child: _tab == 0
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              const Text(
                                'Add work across characters',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _kind,
                                decoration: const InputDecoration(
                                  labelText: 'Save destination',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'additional',
                                    child: Text(
                                      'Additional portraits · character gallery',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'expressions',
                                    child: Text('Expression set · starter (8)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'portrait',
                                    child: Text('Primary portrait'),
                                  ),
                                ],
                                onChanged: busy
                                    ? null
                                    : (v) => setState(() => _kind = v!),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Additional portraits are saved to the character’s gallery. They do not replace the primary portrait or become expressions.',
                                ),
                              ),
                              TextField(
                                controller: _prompt,
                                enabled: !busy,
                                minLines: 2,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Prompt / instruction',
                                  hintText:
                                      'Use {character} for each character’s name.',
                                ),
                              ),
                              if (_kind != 'expressions')
                                CheckboxListTile(
                                  value: _edit,
                                  onChanged: busy
                                      ? null
                                      : (v) => setState(() => _edit = v!),
                                  title: const Text(
                                    'Edit the current character portrait',
                                  ),
                                ),
                              if (_kind == 'expressions')
                                CheckboxListTile(
                                  value: _missing,
                                  onChanged: busy
                                      ? null
                                      : (v) => setState(() => _missing = v!),
                                  title: const Text('Only missing expressions'),
                                ),
                              Text(
                                'Uses current Image Studio settings: ${queue.snapshot()['backend']} · ${_edit || _kind == 'expressions' ? queue.snapshot()['editModel'] : queue.snapshot()['model']}',
                              ),
                              const Text(
                                'Source images and prompts are captured when prepared. Changing generation settings pauses older waiting work until those settings are restored.',
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => showWarmDialogOf<void>(
                                          context,
                                          builder: (_) => const ImageStudio(
                                            mode: ImageGenMode.customPrompt,
                                          ),
                                        ),
                                  icon: const Icon(Icons.tune),
                                  label: const Text(
                                    'Configure in Image Studio',
                                  ),
                                ),
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Find characters',
                                ),
                                onChanged: (v) =>
                                    setState(() => _search = v.toLowerCase()),
                              ),
                              for (final card in repo.characters.where(
                                (c) =>
                                    c.dbId != null &&
                                    c.name.toLowerCase().contains(_search),
                              ))
                                CheckboxListTile(
                                  value: _selected.contains(card.dbId),
                                  title: Text(card.name),
                                  onChanged: busy
                                      ? null
                                      : (v) => setState(() {
                                          if (v!) {
                                            _selected.add(card.dbId!);
                                          } else {
                                            _selected.remove(card.dbId);
                                          }
                                        }),
                                ),
                              FilledButton(
                                onPressed: busy || _selected.isEmpty
                                    ? null
                                    : () => _action(() async {
                                        await queue.prepare(
                                          repository: repo,
                                          characterIds: _selected.toList(),
                                          kind: _kind,
                                          prompt: _prompt.text,
                                          edit: _edit,
                                          missingOnly: _missing,
                                        );
                                        if (mounted) {
                                          setState(() {
                                            _tab = 1;
                                            _error = null;
                                          });
                                        }
                                      }),
                                child: Text(
                                  'Prepare for ${_selected.length} characters',
                                ),
                              ),
                            ],
                          )
                        : ImageBatchResults(
                            queue: queue,
                            review: _tab == 2,
                            onAction: _action,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<bool> confirmImageBatchSave(
  BuildContext context,
  ImageBatchService queue,
) async {
  final portraits = queue.jobs
      .where((j) => j.kind == 'portrait' && j.kept && j.state == 'review')
      .length;
  if (portraits == 0) return true;
  return await showWarmDialog<bool>(
        context,
        title: 'Replace $portraits primary portraits?',
        content: const WarmDialogText(
          'The kept primary portrait candidates will replace those characters’ current portraits. Additional portraits remain in the gallery.',
        ),
        actions: [
          warmDialogCancel(context),
          warmDialogConfirm(
            context,
            label: 'Replace portraits',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ) ??
      false;
}
