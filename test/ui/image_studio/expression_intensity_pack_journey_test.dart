// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/ui/image_studio/studio_widgets.dart';
import 'package:front_porch_ai/services/image_prompt/image_prompt.dart';
import 'package:front_porch_ai/services/image/image.dart';
import 'package:front_porch_ai/services/services.dart';
import 'expression_prompt_rules_pack_journey_test.dart'
    show PackRuleRig, settleIo;

void main() {
  testWidgets(
    'setup intensity reaches generation and retry replaces wording only on request',
    (tester) async {
      final rig = await PackRuleRig.open(tester);
      await rig.pumpWorkspace(tester);
      final source = find.widgetWithText(TextButton, 'Use last Studio picture');
      await settleIo(
        tester,
        () =>
            source.evaluate().isNotEmpty &&
            tester.widget<TextButton>(source).onPressed != null &&
            !tester.hasRunningAnimations,
      );
      await tester.enterText(
        find.byKey(const Key('expression-description')),
        'portrait',
      );
      await tester.ensureVisible(source);
      await tester.tap(source);
      await settleIo(
        tester,
        () => find.byType(ExpressionPackSetup).evaluate().isNotEmpty,
      );
      var picker = find.byType(DropdownButton<ExpressionIntensity>);
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Subtle').last);
      await tester.pumpAndSettle();
      final screenshot = Platform.environment['FPAI_INTENSITY_SCREENSHOT'];
      if (screenshot != null) {
        RenderObject? node = tester.renderObject(
          find.byType(ExpressionPackSetup),
        );
        while (node != null && node is! RenderRepaintBoundary) {
          node = node.parent;
        }
        if (node is RenderRepaintBoundary) {
          final boundary = node;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(screenshot).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.ensureVisible(find.text('Start (8)'));
      await tester.tap(find.text('Start (8)'));
      await settleIo(tester, () => rig.image.prompts.length == 8);
      expect(rig.image.prompts[3], contains('gently tightened lips'));
      final session = expressionPackBoard.run!.session;
      expect(session.intensity, ExpressionIntensity.subtle);
      await tester.tap(
        find.byTooltip('Re-roll (edit prompt, strength, seed)').at(3),
      );
      await tester.pumpAndSettle();
      picker = find.byType(DropdownButton<ExpressionIntensity>).last;
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear').last);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Strong').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        contains('deeply furrowed brows'),
      );
      await tester.tap(
        find.text('Use intensity wording (replaces custom prompt)'),
      );
      await tester.enterText(
        find.byType(TextField).last,
        'my precise expression',
      );
      await tester.tap(find.text('Re-roll'));
      await settleIo(tester, () => rig.image.prompts.length == 9);
      expect(rig.image.prompts.last, 'my precise expression');
      expect(session.slots[3].customPrompt, 'my precise expression');
    },
  );
}
