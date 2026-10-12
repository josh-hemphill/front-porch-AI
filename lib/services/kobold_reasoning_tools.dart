// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/tool_choice_style_probe.dart';
import 'package:front_porch_ai/utils/utils.dart';

/// KoboldCpp 1.122.1 can force reasoning closers through a tool grammar and
/// assert. Keep the zero budget, but request tool JSON without a grammar.
Map<String, dynamic> koboldReasoningToolTextPayload(
  Map<String, dynamic> payload,
  List<Map<String, dynamic>> tools, {
  String? toolChoice,
}) {
  final messages = List<Map<String, dynamic>>.from(payload['messages'] as List);
  final choice =
      toolChoice == null || toolChoice.isEmpty || toolChoice == 'auto'
      ? 'Return an empty tool_calls array if no tool is needed.'
      : toolChoice == kToolChoiceRequired
      ? 'Call at least one of the advertised functions.'
      : 'Call only the function ${jsonEncode(toolChoice)}.';
  messages.add({
    'role': 'user',
    'content':
        'Use the conversation and tool results above to select functions. '
        'Return only a JSON object with a tool_calls array. '
        'Each entry must have name (an advertised function name) and arguments '
        '(an object satisfying that function schema). $choice '
        'Do not invent functions or tool results. Available functions:\n'
        '${jsonEncode(tools)}',
  });
  return {...payload, 'messages': messages}..removeWhere(
    (key, _) => const {
      'tools',
      'tool_choice',
      'grammar',
      'response_format',
      'json_schema',
    }.contains(key),
  );
}

LlmToolResponse? parseKoboldReasoningToolText(
  LlmToolResponse? response,
  List<Map<String, dynamic>> tools, {
  String? toolChoice,
  bool salvageReasoning = false,
}) {
  if (response == null) return null;
  final decoded =
      _toolJson(response.text) ??
      (salvageReasoning ? _toolJson(response.reasoning) : null);
  if (decoded?['tool_calls'] is! List) return response;
  final allowed = tools
      .map((tool) => (tool['function'] as Map?)?['name'])
      .whereType<String>()
      .toSet();
  final named =
      toolChoice != null &&
      toolChoice.isNotEmpty &&
      toolChoice != 'auto' &&
      toolChoice != kToolChoiceRequired;
  final calls = <LlmToolCall>[];
  for (final raw in decoded!['tool_calls'] as List) {
    if (raw is! Map) continue;
    final name = raw['name'];
    final arguments = raw['arguments'];
    if (name is! String ||
        !allowed.contains(name) ||
        arguments is! Map ||
        arguments.keys.any((key) => key is! String) ||
        (named && name != toolChoice)) {
      continue;
    }
    calls.add(
      LlmToolCall(name: name, arguments: Map<String, dynamic>.from(arguments)),
    );
  }
  return LlmToolResponse(
    calls: calls,
    text: '',
    reasoning: response.reasoning,
    promptTokens: response.promptTokens,
    completionTokens: response.completionTokens,
    totalTokens: response.totalTokens,
    finishReason: calls.isEmpty ? response.finishReason : 'tool_calls',
  );
}

Map<String, dynamic>? _toolJson(String text) {
  final clean = stripThinkBlocks(text);
  final start = clean.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var quoted = false;
  var escaped = false;
  for (var i = start; i < clean.length; i++) {
    final ch = clean[i];
    if (quoted) {
      if (escaped) {
        escaped = false;
      } else if (ch == r'\') {
        escaped = true;
      } else if (ch == '"') {
        quoted = false;
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == '{') {
      depth++;
    } else if (ch == '}' && --depth == 0) {
      return JsonSanitizer.tryParse(clean.substring(start, i + 1));
    }
  }
  return null;
}
