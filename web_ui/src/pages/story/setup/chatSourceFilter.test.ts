// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import { describe, expect, it } from 'vitest';
import { filterChatSources, type ChatSourceRow } from './ChatSourcePicker';

const row = (character_name: string, session_name: string): ChatSourceRow => ({
  character_id: character_name, character_name, session_id: `${character_name}-${session_name}`,
  session_name, date: '2026-10-01T00:00:00.000', message_count: 40, short: false,
});

const rows = [row('Mira Vale', 'The lighthouse'), row('Dov Marsh', 'Letters'), row('Mira Vale', 'Second winter')];

describe('filterChatSources', () => {
  it('returns everything for an empty search', () => {
    expect(filterChatSources(rows, '  ')).toHaveLength(3);
  });

  it('matches the character name, ignoring case', () => {
    expect(filterChatSources(rows, 'mira').map((r) => r.session_name)).toEqual(['The lighthouse', 'Second winter']);
  });

  it('needs every word, across character and chat name', () => {
    expect(filterChatSources(rows, 'vale winter').map((r) => r.session_name)).toEqual(['Second winter']);
    expect(filterChatSources(rows, 'dov winter')).toHaveLength(0);
  });
});
