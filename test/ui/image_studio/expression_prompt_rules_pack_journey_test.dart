// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:front_porch_ai/database/database.dart';
import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/capability/capability.dart';
import 'package:front_porch_ai/services/image/image.dart';
import 'package:front_porch_ai/services/image_prompt/image_prompt.dart';
import 'package:front_porch_ai/ui/image_studio/expression_pack_dialog.dart';
import 'package:front_porch_ai/ui/image_studio/expression_pack_widgets.dart';
import 'package:front_porch_ai/ui/avatar_creation/avatar_creation_widgets.dart';

class PortraitImages extends ChangeNotifier implements ImageGenService {
  @override
  bool get isConfigured => true;
  @override
  String get statusMessage => '';
  @override
  bool get isGenerating => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final prompts = <String>[];
  final picture = Uint8List.fromList(
    img.encodePng(img.Image(width: 64, height: 80)),
  );
  @override
  Future<Uint8List?> generateImage({
    required String prompt,
    String? negativePrompt,
    String? size,
    Uint8List? referenceImage,
    String? model,
    bool isPortrait = false,
    int? seed,
    double? denoise,
    StudioIntent intent = StudioIntent.create,
    double? editStrength,
  }) async {
    prompts.add(prompt);
    return picture;
  }
}

void main() {
  for (final useLocal in [false, true]) {
    testWidgets(
      'actual pack setup forwards ${useLocal ? 'local' : 'cancelled default'} rules and grid edits affect rerolls',
      (tester) async {
        final rig = await PackRuleRig.open(tester);
        await rig.pump(
          tester,
          (context) => ExpressionPackDialog.launch(
            context,
            characterDbId: rig.card.dbId!,
            characterName: rig.card.name,
            repository: rig.repository,
            candidateBase: rig.image.picture,
            basePrompt: 'portrait',
            negativePrompt: '',
          ),
        );
        await tester.tap(find.text('Open'));
        await settleIo(
          tester,
          () => find.byType(ExpressionPackSetup).evaluate().isNotEmpty,
        );
        await tester.tap(find.text('Prompt rules…'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Text before each prompt'),
          'edited',
        );
        await tester.tap(find.text('Save as global defaults'));
        await settleIo(
          tester,
          () => find.text('Global defaults saved.').evaluate().isNotEmpty,
        );
        await tester.tap(
          find.text(useLocal ? 'Use for this pack' : 'Cancel').last,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Start (8)'));
        await tester.tap(find.text('Start (8)'));
        await settleIo(
          tester,
          () =>
              rig.image.prompts.length == 8 &&
              find.byType(ExpressionPackGrid).evaluate().isNotEmpty,
        );
        expect(
          rig.image.prompts,
          everyElement(startsWith(useLocal ? 'edited' : 'original')),
        );
        expect(
          rig.storage.expressionSettings.expressionPromptRules.prefix,
          'edited',
        );
        await tester.tap(find.text('Prompt rules…'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Text before each prompt'),
          'grid wording',
        );
        await tester.tap(find.text('Use for this pack'));
        await tester.pumpAndSettle();
        expect(
          expressionPackBoard.run!.session.promptRules.prefix,
          'grid wording',
        );
        await tester.tap(
          find.byTooltip('Re-roll (edit prompt, strength, seed)').first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Re-roll'));
        await settleIo(tester, () => rig.image.prompts.length == 9);
        expect(rig.image.prompts.last, startsWith('grid wording'));
      },
    );
  }
  testWidgets(
    'creator Save defaults then Cancel keeps current rules but next creator snapshots new defaults',
    (tester) async {
      final rig = await PackRuleRig.open(tester);
      final controller = rig.creator();
      addTearDown(controller.dispose);
      await rig.pump(
        tester,
        (context) => editCreatorPromptRules(context, controller),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Text before each prompt'),
        'saved',
      );
      await tester.tap(find.text('Save as global defaults'));
      await settleIo(
        tester,
        () =>
            rig.storage.expressionSettings.expressionPromptRules.prefix ==
            'saved',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.packPromptRules.prefix, 'original');
      final next = rig.creator();
      expect(next.packPromptRules.prefix, 'saved');
      next.dispose();
    },
  );
}

Future<void> settleIo(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
  expect(done(), isTrue);
}

class PackRuleRig {
  PackRuleRig(this.storage, this.repository, this.image, this.card);
  final StorageService storage;
  final CharacterRepository repository;
  final PortraitImages image;
  final CharacterCard card;
  static Future<PackRuleRig> open(WidgetTester tester) async {
    late PackRuleRig rig;
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      final dir = await Directory.systemTemp.createTemp('pack_rules_ui_');
      final storage = StorageService.sandbox(dir.path);
      final prefs = await SharedPreferences.getInstance();
      storage.imageGenSettings.initializeBase(prefs, () {});
      storage.expressionSettings.initializeBase(prefs, () {});
      await storage.imageGenSettings.setImageGenBackend('a1111');
      await storage.expressionSettings.setExpressionPromptRules(
        ExpressionPromptRules(prefix: 'original'),
      );
      final db = AppDatabase.forTesting();
      final repository = CharacterRepository(db, storage);
      await repository.loadCharacters();
      final card = CharacterCard(name: 'Pack rules portrait');
      await repository.addCharacter(card);
      final image = PortraitImages();
      rig = PackRuleRig(storage, repository, image, card);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        expressionPackBoard.clear();
        image.dispose();
        repository.dispose();
        storage.dispose();
        await db.close();
        await dir.delete(recursive: true);
      });
    });
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    return rig;
  }

  Future<void> pump(
    WidgetTester tester,
    Future<Object?> Function(BuildContext) open,
  ) => tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: storage),
        ChangeNotifierProvider<ImageGenService>.value(value: image),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => open(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  AvatarCreationController creator() => AvatarCreationController(
    ensureCardSaved: () async => card,
    repository: repository,
    storage: storage,
    imageGen: image,
    resolveVisionFire: () async => null,
    peekVisionSupport: () async => null,
    initialPrompt: 'portrait',
    card: card,
  );
}
