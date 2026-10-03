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

/// Below this many messages a chat is flagged as short in the "Start from a
/// chat" picker: it can still be picked, but there is little for a story to
/// be built on.
const int kShortChatMessages = 20;

/// How many chats the picker lists at once; search narrows the rest.
const int kChatSourcePageSize = 50;

/// One 1:1 chat a story can start from.
class StoryChatSourceRow {
  const StoryChatSourceRow({
    required this.characterId,
    required this.characterName,
    required this.sessionId,
    required this.sessionName,
    required this.summary,
    required this.createdAt,
    required this.messageCount,
  });

  final String characterId;
  final String characterName;
  final String sessionId;
  final String sessionName;
  final String summary;
  final DateTime createdAt;
  final int messageCount;

  bool get isShort => messageCount < kShortChatMessages;

  Map<String, dynamic> toJson() => {
    'character_id': characterId,
    'character_name': characterName,
    'session_id': sessionId,
    'session_name': sessionName,
    'date': createdAt.toIso8601String(),
    'message_count': messageCount,
    'short': isShort,
  };
}

/// [rows] whose character or chat name contains every word of [query].
List<StoryChatSourceRow> filterChatSources(
  List<StoryChatSourceRow> rows,
  String query,
) {
  final words = query.toLowerCase().split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return rows;
  return rows.where((r) {
    final hay = '${r.characterName} ${r.sessionName}'.toLowerCase();
    return words.every(hay.contains);
  }).toList();
}
