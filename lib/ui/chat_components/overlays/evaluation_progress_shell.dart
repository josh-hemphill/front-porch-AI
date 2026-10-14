// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

class EvaluationProgressShell extends StatefulWidget {
  const EvaluationProgressShell({
    super.key,
    required this.title,
    required this.details,
    this.onStop,
    this.stopLabel = 'Stop this reply',
  });

  final String title;
  final Widget details;
  final VoidCallback? onStop;
  final String stopLabel;

  @override
  State<EvaluationProgressShell> createState() =>
      _EvaluationProgressShellState();
}

class _EvaluationProgressShellState extends State<EvaluationProgressShell> {
  bool _minimized = false;
  int _seconds = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = timer.tick;
      if (_seconds >= 30) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _seconds;
    final status = seconds < 30
        ? widget.title
        : '${widget.title} · ${seconds}s elapsed';
    final controls = Material(
      color: AppColors.surfaceOf(context),
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_minimized) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.porchAmberOf(context),
                ),
              ),
              Text(
                status,
                style: TextStyle(color: AppColors.textPrimary(context)),
              ),
            ] else if (seconds >= 30)
              Text('${seconds}s elapsed'),
            TextButton.icon(
              onPressed: () => setState(() => _minimized = !_minimized),
              icon: Icon(_minimized ? Icons.open_in_full : Icons.minimize),
              label: Text(
                _minimized ? 'Show evaluation details' : 'Minimize evaluation',
              ),
            ),
            if (_minimized && widget.onStop != null)
              TextButton(
                onPressed: widget.onStop,
                child: Text(widget.stopLabel),
              ),
          ],
        ),
      ),
    );
    if (_minimized) {
      return Positioned(
        top: 12,
        left: 12,
        right: 12,
        child: SafeArea(bottom: false, child: controls),
      );
    }
    return Positioned.fill(
      child: Stack(
        children: [
          widget.details,
          Positioned(
            top: 12,
            right: 12,
            left: 12,
            child: SafeArea(
              bottom: false,
              child: Align(alignment: Alignment.topRight, child: controls),
            ),
          ),
        ],
      ),
    );
  }
}
