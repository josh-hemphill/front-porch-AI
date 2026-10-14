// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/ui/chat_components/chat_components.dart';

void main() {
  testWidgets('minimizing keeps chat readable and phase actions available', (
    tester,
  ) async {
    var reads = 0;
    var stops = 0;
    var skips = 0;
    var active = true;
    var objective = false;
    var session = 'one';
    Future<void> render() => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(
                child: TextButton(
                  onPressed: () => reads++,
                  child: const Text('Read chat'),
                ),
              ),
              if (active)
                EvaluationProgressShell(
                  key: ValueKey(session),
                  title: objective ? 'Objective Engine' : 'Realism Engine',
                  onStop: objective ? () => skips++ : () => stops++,
                  stopLabel: objective ? 'Skip goal check' : 'Stop this reply',
                  details: const Positioned.fill(
                    child: Material(
                      child: Center(child: Text('Live evaluation details')),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await render();
    expect(find.text('Live evaluation details'), findsOneWidget);
    await tester.tap(find.text('Minimize evaluation'));
    await tester.pump();
    expect(find.text('Live evaluation details'), findsNothing);
    await tester.tap(find.text('Read chat'));
    expect(reads, 1);
    expect(stops, 0);
    await tester.pump(const Duration(seconds: 31));
    expect(find.textContaining('31s elapsed'), findsOneWidget);
    await tester.tap(find.text('Stop this reply'));
    expect(stops, 1);
    objective = true;
    await render();
    expect(find.text('Show evaluation details'), findsOneWidget);
    await tester.tap(find.text('Skip goal check'));
    expect(skips, 1);
    await tester.tap(find.text('Show evaluation details'));
    await tester.pump();
    expect(find.text('Live evaluation details'), findsOneWidget);
    await tester.tap(find.text('Minimize evaluation'));
    await tester.pump();
    session = 'other';
    await render();
    expect(find.text('Minimize evaluation'), findsOneWidget);
    active = false;
    await render();
    expect(find.byType(EvaluationProgressShell), findsNothing);
    active = true;
    await render();
    expect(find.text('Minimize evaluation'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
