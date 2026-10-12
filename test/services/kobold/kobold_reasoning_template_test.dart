// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/services.dart';

void main() {
  const tools = '<tools>\n{"name":"report_result"}\n</tools>\n';
  test(
    'only a rendered tool prompt with a closed empty Qwen think prefix passes',
    () {
      for (final prefix in [
        '<|im_start|>assistant\n<think>\n\n</think>\n\n',
        '<|im_start|>assistant\n<think></think>',
      ]) {
        expect(
          koboldRenderedTemplateDisablesThinking(
            '$tools$prefix',
            'report_result',
          ),
          isTrue,
        );
      }
    },
  );
  test('open thinking, thinking content and legacy fallback do not pass', () {
    for (final prefix in [
      '<|im_start|>assistant\n<think>\n',
      '<|im_start|>assistant\n<think>thoughts</think>',
      '<|im_start|>assistant\n<think></think>\n<think>',
      '### Response:',
      '<|im_start|>assistant\n',
      '<|im_start|>assistant\n<think></think>unverified suffix',
    ]) {
      expect(
        koboldRenderedTemplateDisablesThinking(
          '$tools$prefix',
          'report_result',
        ),
        isFalse,
        reason: prefix,
      );
    }
  });
  test(
    'a closed prefix alone or unrelated tool definitions are insufficient',
    () {
      const prefix = '<|im_start|>assistant\n<think></think>';
      expect(
        koboldRenderedTemplateDisablesThinking(prefix, 'report_result'),
        isFalse,
      );
      expect(
        koboldRenderedTemplateDisablesThinking('$tools$prefix', 'unknown'),
        isFalse,
      );
    },
  );
}
