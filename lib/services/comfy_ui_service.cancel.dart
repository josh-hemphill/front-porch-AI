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

part of 'comfy_ui_service.dart';

extension ComfyUiCancellation on ComfyUiService {
  void beginGeneration() {
    _activePrompt = ComfyPromptCancellation();
  }

  /// Stop only the prompt owned by this client. Local polling stops even if
  /// this ComfyUI version does not support the job-specific cancel endpoint.
  Future<void> cancelActivePrompt() async {
    final run = _activePrompt;
    if (run == null) return;
    run.cancel();
    final id = run.promptId;
    if (id != null) await _cancelRemotePrompt(id);
  }

  Future<void> _cancelRemotePrompt(String id) async {
    try {
      await http
          .post(Uri.parse('$_root/api/jobs/${Uri.encodeComponent(id)}/cancel'))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('ComfyUI: prompt cancellation unavailable ($e)');
    }
  }
}
