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

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/image/image.dart';

void main() {
  final qwenLatentEdit = {
    'nodes': [
      {'id': 1, 'type': 'qwen-edit-subgraph'},
    ],
    'links': <Object>[],
    'definitions': {
      'subgraphs': [
        {
          'id': 'qwen-edit-subgraph',
          'nodes': [
            {'id': 2, 'type': 'LoadImage'},
            {'id': 3, 'type': 'TextEncodeQwenImage21'},
            {'id': 4, 'type': 'VAEEncode'},
            {'id': 5, 'type': 'KSampler'},
          ],
        },
      ],
    },
  };

  test('saved Qwen latent-source subgraph belongs in the Edit menu', () {
    expect(savedGraphIsEdit(qwenLatentEdit), isTrue);
    expect(deskGraphStance(jsonEncode(qwenLatentEdit)), 'edit');
  });

  test('API-format Qwen source latent is also an Edit graph', () {
    expect(
      savedGraphIsEdit({
        'image': {'class_type': 'LoadImage'},
        'encoder': {'class_type': 'TextEncodeQwenImage21'},
        'latent': {'class_type': 'VAEEncode'},
        'sampler': {'class_type': 'KSampler'},
      }),
      isTrue,
    );
  });

  test('ordinary img2img still belongs in Create', () {
    expect(
      savedGraphIsEdit({
        'image': {'class_type': 'LoadImage'},
        'latent': {'class_type': 'VAEEncode'},
        'sampler': {'class_type': 'KSampler'},
      }),
      isFalse,
    );
  });
}
