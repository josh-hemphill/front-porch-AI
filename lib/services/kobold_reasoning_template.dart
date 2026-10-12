// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Known Qwen reasoning-off generation prefix plus native tool definitions.
/// An arbitrary template file or a mention of enable_thinking is insufficient.
bool koboldRenderedTemplateDisablesThinking(
  String prompt,
  String functionName,
) {
  final toolsStart = prompt.lastIndexOf('<tools>');
  final toolsEnd = prompt.lastIndexOf('</tools>');
  if (toolsStart < 0 ||
      toolsEnd <= toolsStart ||
      !prompt
          .substring(toolsStart, toolsEnd)
          .contains(jsonEncode(functionName))) {
    return false;
  }
  return RegExp(
    r'<\|im_start\|>assistant\s*<think>\s*</think>\s*$',
  ).hasMatch(prompt.substring(toolsEnd));
}

/// Token counting renders a request without sampling. Named choice avoids
/// the legacy auto-tool selector's internal generation on this endpoint.
Future<bool> koboldTemplateDisablesThinking({
  required http.Client client,
  required String baseUrl,
  required Map<String, dynamic> payload,
  required List<Map<String, dynamic>> tools,
}) async {
  final function = tools.firstOrNull?['function'];
  final name = function is Map ? function['name'] : null;
  if (name is! String || name.isEmpty) return false;
  try {
    final response = await client
        .post(
          Uri.parse('$baseUrl/api/extra/tokencount'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            ...payload,
            'stream': false,
            'tools': tools,
            'tool_choice': {
              'type': 'function',
              'function': {'name': name},
            },
          }),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return false;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['value'] is! num || decoded['value'] < 0) {
      return false;
    }
    var prompt = decoded['prompt'];
    if (prompt is! String && decoded['ids'] is List) {
      final detokenized = await client
          .post(
            Uri.parse('$baseUrl/api/extra/detokenize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'ids': decoded['ids'], 'special': true}),
          )
          .timeout(const Duration(seconds: 5));
      if (detokenized.statusCode != 200) return false;
      final decodedText = jsonDecode(detokenized.body);
      prompt = decodedText is Map ? decodedText['result'] : null;
    }
    return prompt is String &&
        koboldRenderedTemplateDisablesThinking(prompt, name);
  } on Object catch (error) {
    debugPrint('[OpenAiChat] Template rendering could not be verified: $error');
    return false;
  }
}
