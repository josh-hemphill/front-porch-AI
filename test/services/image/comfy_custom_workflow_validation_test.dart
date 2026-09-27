// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/image/comfy_workflow_convert.dart';
import 'package:front_porch_ai/services/image/comfy_prompt_errors.dart';

void main() {
  test('custom widgets survive UI export and comparison chrome is omitted', () {
    final graph = convertComfyUiToApi(
      {
        'nodes': [
          {
            'id': 505,
            'type': 'QwenPERewriteT8',
            'inputs': [],
            'widgets_values': [
              'rewrite this portrait',
              'edit',
              'auto',
              'English',
              false,
              'text.gguf',
              'edit.gguf',
              'vision.gguf',
              'after_run',
              42,
              'randomize',
            ],
          },
          {
            'id': 513,
            'type': 'LoraLoaderModelOnly',
            'inputs': [],
            'widgets_values': ['turbo.safetensors', 0.7],
          },
          {
            'id': 500,
            'type': 'TextGenerate',
            'inputs': [],
            'widgets_values': [
              'prompt',
              512,
              'on',
              1.0,
              20,
              0.95,
              0.05,
              1.05,
              0.0,
              42,
              true,
              false,
              'auto',
            ],
          },
          {
            'id': 472,
            'type': 'ImageCompare',
            'inputs': [],
            'widgets_values': [],
          },
        ],
        'links': [],
      },
      objectInfo: {
        'QwenPERewriteT8': {
          'input': {
            'required': {
              'user_prompt': ['STRING', {}],
              'task': [
                ['auto', 'edit'],
                {},
              ],
              'aspect_ratio': [
                ['auto', '1:1'],
                {},
              ],
              'output_language': [
                ['auto', 'English'],
                {},
              ],
              'transparent_rgba': ['BOOLEAN', {}],
              't2i_model': [
                ['text.gguf'],
                {},
              ],
              'edit_model': [
                ['edit.gguf'],
                {},
              ],
              'vision_model': [
                ['vision.gguf'],
                {},
              ],
              'model_lifetime': [
                ['after_run'],
                {},
              ],
              'seed': ['INT', {}],
            },
          },
        },
        'LoraLoaderModelOnly': {
          'input': {
            'required': {
              'model': ['MODEL', {}],
              'lora_name': [
                ['turbo.safetensors'],
                {},
              ],
              'strength_model': ['FLOAT', {}],
            },
          },
        },
        'TextGenerate': {
          'input': {
            'required': {
              'prompt': ['STRING', {}],
              'max_length': ['INT', {}],
              'sampling_mode': [
                'COMFY_DYNAMICCOMBO_V3',
                {
                  'options': [
                    {
                      'key': 'on',
                      'inputs': {
                        'required': {
                          'temperature': ['FLOAT', {}],
                          'top_k': ['INT', {}],
                          'top_p': ['FLOAT', {}],
                          'min_p': ['FLOAT', {}],
                          'repetition_penalty': ['FLOAT', {}],
                          'presence_penalty': ['FLOAT', {}],
                          'seed': ['INT', {}],
                        },
                      },
                    },
                  ],
                },
              ],
              'thinking': ['BOOLEAN', {}],
              'use_default_template': ['BOOLEAN', {}],
              'mtp': [
                ['auto', 'off'],
                {},
              ],
            },
          },
        },
      },
    );

    final rewrite = (graph['505'] as Map)['inputs'] as Map;
    expect(rewrite['task'], 'edit');
    expect(rewrite['t2i_model'], 'text.gguf');
    expect(rewrite['edit_model'], 'edit.gguf');
    expect(rewrite['seed'], 42);
    final lora = (graph['513'] as Map)['inputs'] as Map;
    expect(lora['lora_name'], 'turbo.safetensors');
    expect(lora['strength_model'], 0.7);
    final text = (graph['500'] as Map)['inputs'] as Map;
    expect(text['sampling_mode.temperature'], 1.0);
    expect(text['sampling_mode.top_k'], 20);
    expect(text['thinking'], true);
    expect(text['mtp'], 'auto');
    expect(graph.containsKey('472'), false);
  });

  test('prompt rejection identifies the node and missing input', () {
    final message = describeComfyPromptError({
      'error': {'message': 'Prompt outputs failed validation'},
      'node_errors': {
        '459_513': {
          'class_type': 'LoraLoaderModelOnly',
          'errors': [
            {'message': 'Required input is missing', 'details': 'lora_name'},
          ],
        },
      },
    }, fallback: 'HTTP 400');

    expect(message, contains('LoraLoaderModelOnly 459_513: lora_name'));
  });
}
