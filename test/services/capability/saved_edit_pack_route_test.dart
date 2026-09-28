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

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/capability/image_reference_resolver.dart';
import 'package:front_porch_ai/services/storage/settings/image_gen_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('selected saved Edit workflow cannot silently use Create', () async {
    final settings = ImageGenSettings();
    SharedPreferences.setMockInitialValues({
      settings.k('image_gen_backend'): 'comfyui',
      settings.k('comfy_edit_workflow_id'): 'comfy:userdata:latent_source',
    });
    settings.initializeBase(await SharedPreferences.getInstance(), () {});
    settings.load();

    expect(
      ImageReferenceResolver.unreadySelectedSavedEdit(
        settings,
        editMode: false,
      ),
      isTrue,
    );
    expect(
      ImageReferenceResolver.unreadySelectedSavedEdit(settings, editMode: true),
      isFalse,
    );
    await settings.setComfyEditWorkflowId('qwen_image_edit');
    expect(
      ImageReferenceResolver.unreadySelectedSavedEdit(
        settings,
        editMode: false,
      ),
      isFalse,
    );
  });
}
