// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'expression_pack_service.dart';

extension ExpressionPackIntensity on ExpressionPackSession {
  ExpressionIntensity get intensity => _intensity;
  ExpressionIntensity effectiveIntensityFor(int index) =>
      _slots[index].intensityOverride ?? _intensity;

  String intensityPromptFor(int index, ExpressionIntensity level) =>
      _promptRules.apply(
        originalExpressionPrompt(
          emotion: _slots[index].emotion,
          basePrompt: _basePrompt,
          editMode: _editMode,
          intensity: level,
        ),
      );

  bool updateIntensity(ExpressionIntensity level) {
    if (_running || _disposed) return false;
    _intensity = level;
    _notifyIntensityChange();
    return true;
  }
}
