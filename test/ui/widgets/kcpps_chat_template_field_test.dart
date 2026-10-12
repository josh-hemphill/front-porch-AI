// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/ui/dialogs/kcpps_editor/kcpps_editor.dart';

void main() {
  testWidgets('choose and clear the template with restart guidance', (
    tester,
  ) async {
    var selected = '';
    final repaint = GlobalKey();
    final capture = Platform.environment['FPAI_TEMPLATE_CAPTURE'];
    if (capture != null && Platform.isWindows) {
      await tester.runAsync(() async {
        final font = FontLoader('Segoe UI')
          ..addFont(
            File(
              'C:/Windows/Fonts/segoeui.ttf',
            ).readAsBytes().then(ByteData.sublistView),
          );
        await font.load();
      });
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Segoe UI'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 650,
              height: 220,
              child: RepaintBoundary(
                key: repaint,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return KcppsChatTemplateField(
                      path: selected,
                      pickFile: () async =>
                          'E:/models/example-chat-template.jinja',
                      onChanged: (path) => setState(() => selected = path),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('stop and restart KoboldCpp'), findsOneWidget);
    await tester.tap(find.text('Choose .jinja file…'));
    await tester.pumpAndSettle();
    expect(selected, 'E:/models/example-chat-template.jinja');
    expect(find.text('Use embedded template'), findsOneWidget);
    if (capture != null) {
      await tester.runAsync(() async {
        final image =
            await (repaint.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(capture).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.text('Use embedded template'));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(find.text('Choose .jinja file…'), findsOneWidget);
  });
}
