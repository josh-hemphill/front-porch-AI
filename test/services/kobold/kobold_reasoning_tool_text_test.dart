// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/services.dart';

const _tools = <Map<String, dynamic>>[
  {
    'type': 'function',
    'function': {'name': 'read_book'},
  },
  {
    'type': 'function',
    'function': {'name': 'find_book'},
  },
];

void main() {
  test(
    'the safe request preserves sampling and disables constrained output',
    () {
      final source = <String, dynamic>{
        'messages': [
          {'role': 'user', 'content': 'A synthetic book lookup'},
        ],
        'max_tokens': 4000,
        'temperature': 0.1,
        'reasoning_effort': 'none',
        'chat_template_kwargs': {'enable_thinking': false},
        'tools': _tools,
        'tool_choice': 'required',
        'grammar': 'a grammar',
        'response_format': {'type': 'json_object'},
      };
      final before = jsonEncode(source);
      final payload = koboldReasoningToolTextPayload(
        source,
        _tools,
        toolChoice: 'read_book',
      );
      expect(jsonEncode(source), before);
      for (final key in [
        'max_tokens',
        'temperature',
        'reasoning_effort',
        'chat_template_kwargs',
      ]) {
        expect(payload[key], source[key]);
      }
      for (final key in [
        'tools',
        'tool_choice',
        'grammar',
        'response_format',
      ]) {
        expect(payload.containsKey(key), isFalse);
      }
      expect(
        (payload['messages'] as List).first,
        (source['messages'] as List).first,
      );
    },
  );

  LlmToolResponse? decode(String text, {String? choice}) =>
      parseKoboldReasoningToolText(
        LlmToolResponse(calls: [], text: text),
        _tools,
        toolChoice: choice,
      );

  test(
    'a repeated fenced answer is consumed once, preserving nested strings',
    () {
      final json = jsonEncode({
        'tool_calls': [
          {
            'name': 'read_book',
            'arguments': {'title': 'a "quoted" {title}'},
          },
        ],
      });
      final result = decode('```json\n$json\n```\n```json\n$json\n```')!;
      expect(result.calls, hasLength(1));
      expect(result.calls.single.arguments['title'], 'a "quoted" {title}');
      expect(result.calls.single.id, isEmpty);
    },
  );

  test(
    'unknown functions, wrong named choices and non-object arguments are dropped',
    () {
      final json = jsonEncode({
        'tool_calls': [
          {'name': 'unadvertised', 'arguments': {}},
          {'name': 'find_book', 'arguments': {}},
          {'name': 'read_book', 'arguments': []},
          {
            'name': 'read_book',
            'arguments': {'title': 'Synthetic book'},
          },
        ],
      });
      final result = decode(json, choice: 'read_book')!;
      expect(result.calls, hasLength(1));
      expect(result.calls.single.name, 'read_book');
      expect(result.calls.single.arguments['title'], 'Synthetic book');
    },
  );

  test(
    'auto can choose no functions; truncated JSON cannot execute a call',
    () {
      expect(decode('{"tool_calls": []}')!.calls, isEmpty);
      expect(
        decode('{"tool_calls": [{"name": "read_book", "arguments": {')!.calls,
        isEmpty,
      );
    },
  );

  test('reasoning is only parsed when the caller permits salvage', () {
    const response = LlmToolResponse(
      calls: [],
      text: '',
      reasoning: '{"tool_calls": [{"name": "read_book", "arguments": {}}]}',
    );
    expect(parseKoboldReasoningToolText(response, _tools)!.calls, isEmpty);
    expect(
      parseKoboldReasoningToolText(
        response,
        _tools,
        salvageReasoning: true,
      )!.calls,
      hasLength(1),
    );
  });
}
