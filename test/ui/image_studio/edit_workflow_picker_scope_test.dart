// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/services/image_gen_service.dart';
import 'package:front_porch_ai/services/storage/settings/backend_settings.dart';
import 'package:front_porch_ai/services/storage/settings/image_gen_settings.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/ui/image_studio/comfy_create_panel.dart';
import 'package:front_porch_ai/ui/image_studio/generation_options_tab.dart';

class _Storage extends ChangeNotifier implements StorageService {
  _Storage() {
    imageGenSettings.initializeBase(null, notifyListeners);
    imageGenSettings.setImageGenBackend('comfyui');
    imageGenSettings.setComfyUiUrl('');
  }

  @override
  final imageGenSettings = ImageGenSettings();
  @override
  final backendSettings = BackendSettings();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImageGen extends ChangeNotifier implements ImageGenService {
  @override
  Future<List<ImageModelInfo>> fetchImageModels() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Edit settings do not show the Create workflow picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final storage = _Storage();
    final imageGen = _ImageGen();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageService>.value(value: storage),
          ChangeNotifierProvider<ImageGenService>.value(value: imageGen),
        ],
        child: MaterialApp(
          home: const Scaffold(body: GenerationOptionsTab(editScoped: true)),
        ),
      ),
    );
    expect(find.byType(ComfyCreatePanel), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
