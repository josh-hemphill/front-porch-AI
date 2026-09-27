// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Show the node and input that ComfyUI rejected, when its response includes
/// node_errors. The top-level message alone is usually just validation failed.
String describeComfyPromptError(Object? response, {required String fallback}) {
  if (response is! Map) return fallback;
  final error = response['error'];
  final message = error is Map ? error['message']?.toString() : null;
  final details = error is Map ? error['details']?.toString() : null;
  final problems = <String>[];
  final nodes = response['node_errors'];
  if (nodes is Map) {
    for (final entry in nodes.entries) {
      final node = entry.value;
      if (node is! Map) continue;
      final label = node['class_type']?.toString() ?? 'Node';
      final errors = node['errors'];
      if (errors is! List) continue;
      for (final issue in errors) {
        if (issue is! Map) continue;
        final detail = issue['details']?.toString();
        final summary = detail != null && detail.isNotEmpty
            ? detail
            : issue['message']?.toString();
        if (summary == null || summary.isEmpty) continue;
        problems.add('$label ${entry.key}: $summary');
        if (problems.length == 5) break;
      }
      if (problems.length == 5) break;
    }
  }
  final head = message == null || message.isEmpty ? fallback : message;
  if (problems.isNotEmpty) return '$head — ${problems.join('; ')}';
  if (details != null && details.isNotEmpty) return '$head — $details';
  return head;
}
