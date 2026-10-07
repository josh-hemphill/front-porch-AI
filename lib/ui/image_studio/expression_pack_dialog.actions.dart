// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'expression_pack_dialog.dart';

extension _ExpressionPackActions on _ExpressionPackDialogState {
  Future<void> _resume(ExpressionPackSession session) async {
    _setDialogState(() => _cancelRequested = false);
    final names = await widget.imageGen.startExpressionPack(
      [
        for (final slot in session.slots)
          if (slot.state == ExpressionSlotState.pending) slot.emotion,
      ],
      (_) async {
        await session.run();
        return const <String>[];
      },
    );
    if (!mounted) return;
    if (names == null) {
      _setDialogState(() => _cancelRequested = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(kAlreadyGeneratingMessage)));
    }
  }

  Future<void> _import() async {
    final session = _session!;
    _setDialogState(() => _importing = true);
    final count = await ExpressionPackImporter.importPack(
      repository: widget.repository,
      storage: widget.storage,
      characterDbId: widget.characterDbId,
      characterName: widget.characterName,
      slots: session.slots,
      replaceSameLabel: _replaceExisting,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imported $count expressions for ${widget.characterName} — '
          'expressions enabled',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  /// Header X: confirm when a run is in flight (cancel stops after the
  /// current image; the session is dispose-safe).
  Future<void> _close() async {
    final session = _session;
    if (session != null && session.isRunning) {
      final stop = await showWarmDialog<bool>(
        context,
        title: 'Stop generating?',
        icon: Icons.stop_circle_outlined,
        content: const WarmDialogText(
          'The pack is still generating. Stop after the current image and '
          'discard the results?',
        ),
        actions: [
          warmDialogCancel(context, label: 'Keep going'),
          warmDialogConfirm(
            context,
            label: 'Stop',
            destructive: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
      if (stop != true || !mounted) return;
      session.cancel();
    }
    if (mounted) Navigator.of(context).pop(false);
  }
}
