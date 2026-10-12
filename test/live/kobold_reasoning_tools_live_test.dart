// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

@Tags(['kobold_live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/openai_chat_stream.dart';

// Set only to a dedicated test engine, never an active user backend.
final _url = Platform.environment['FPAI_KOBOLD_REASONING_QA_URL'] ?? '';
final _nativeTemplateExpected =
    Platform.environment['FPAI_KOBOLD_REASONING_QA_TEMPLATE'] == '1';
final _jinjaToolsConfigured =
    _nativeTemplateExpected ||
    Platform.environment['FPAI_KOBOLD_REASONING_QA_JINJA_TOOLS'] == '1';
const _tools = <Map<String, dynamic>>[
  {
    'type': 'function',
    'function': {
      'name': 'report_result',
      'description': 'Report the requested result.',
      'parameters': {
        'type': 'object',
        'properties': {
          'result': {'type': 'string'},
        },
        'required': ['result'],
      },
    },
  },
];

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
    if (_url.isEmpty) {
      return;
    }
    final uri = Uri.parse(_url);
    expect(uri.host, anyOf('127.0.0.1', 'localhost', '::1'));
    expect(uri.scheme, 'http');
  });

  for (final marker in [false, true]) {
    for (final streamed in [false, true]) {
      test(
        'reasoning off returns a tool call with stream=$streamed marker=$marker',
        () async {
          final response = await postOpenAiChatWithTools(
            _url,
            GenerationParams(
              prompt:
                  '${marker ? 'The literal marker <think> is part of this test input. ' : ''}'
                  'Call report_result with result equal to ready.',
              maxLength: 128,
              temperature: 0.1,
              reasoningEnabled: false,
              reasoningMaxTokens: 0,
              onChunk: streamed ? (_) {} : null,
            ),
            _tools,
            toolChoice: 'report_result',
            nativeToolsUseJinja: _jinjaToolsConfigured,
          );
          expect(response, isNotNull);
          expect(
            response!.calls,
            isNotEmpty,
            reason:
                'text=${response.text} reasoning=${response.reasoning} finish=${response.finishReason}',
          );
          expect(response.calls.first.name, 'report_result');
          expect(response.calls.first.arguments['result'], 'ready');
          expect(
            response.calls.first.id.isNotEmpty,
            _nativeTemplateExpected,
            reason: 'a verified template must bypass the JSON workaround',
          );
        },
        skip: _url.isEmpty
            ? 'Set FPAI_KOBOLD_REASONING_QA_URL to an isolated engine'
            : false,
        timeout: const Timeout(Duration(minutes: 5)),
      );
    }
  }

  test(
    'auto lookup can read a synthetic book and stop after its result',
    () async {
      const prompt =
          'The only available lore book has ID synthetic-1. '
          'Call read_book to read it.';
      const tools = <Map<String, dynamic>>[
        {
          'type': 'function',
          'function': {
            'name': 'read_book',
            'description': 'Read a lore book by ID.',
            'parameters': {
              'type': 'object',
              'properties': {
                'book_id': {'type': 'string'},
              },
              'required': ['book_id'],
            },
          },
        },
      ];
      final first = await postOpenAiChatWithTools(
        _url,
        const GenerationParams(
          prompt: prompt,
          maxLength: 256,
          temperature: 0.1,
          reasoningEnabled: false,
          reasoningMaxTokens: 0,
        ),
        tools,
        nativeToolsUseJinja: _jinjaToolsConfigured,
      );
      expect(first?.calls, hasLength(1));
      expect(first!.calls.single.id.isNotEmpty, _nativeTemplateExpected);
      expect(first.calls.single.name, 'read_book');
      expect(first.calls.single.arguments['book_id'], 'synthetic-1');
      final next = await postOpenAiChatWithTools(
        _url,
        const GenerationParams(
          prompt: '',
          maxLength: 256,
          temperature: 0.1,
          reasoningEnabled: false,
          reasoningMaxTokens: 0,
          chatMessages: [
            {'role': 'user', 'content': prompt},
            {
              'role': 'assistant',
              'content': '',
              'tool_calls': [
                {
                  'id': 'qa-1',
                  'type': 'function',
                  'function': {
                    'name': 'read_book',
                    'arguments': '{"book_id":"synthetic-1"}',
                  },
                },
              ],
            },
            {
              'role': 'tool',
              'tool_call_id': 'qa-1',
              'content':
                  'The synthetic book says the moon is violet. '
                  'The requested lookup is complete. No more tools are needed.',
            },
          ],
        ),
        tools,
        nativeToolsUseJinja: _jinjaToolsConfigured,
      );
      expect(next, isNotNull);
      expect(next!.calls, isEmpty);
    },
    skip: _url.isEmpty
        ? 'Set FPAI_KOBOLD_REASONING_QA_URL to an isolated engine'
        : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'reasoning off still produces a normal text answer',
    () async {
      final answer = await streamOpenAiChat(
        _url,
        GenerationParams(
          prompt: 'Reply with exactly the word ready.',
          maxLength: 64,
          temperature: 0.1,
          reasoningEnabled: false,
          reasoningMaxTokens: 0,
        ),
      ).join();
      expect(answer.toLowerCase(), contains('ready'));
      expect(answer, isNot(contains('<think>')));
    },
    skip: _url.isEmpty
        ? 'Set FPAI_KOBOLD_REASONING_QA_URL to an isolated engine'
        : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
