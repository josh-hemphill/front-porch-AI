// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/widgets/widgets.dart';
import 'package:front_porch_ai/utils/utils.dart';

import 'kcpps_editor.dart';

class KcppsChatTemplateField extends StatelessWidget {
  const KcppsChatTemplateField({
    super.key,
    required this.path,
    required this.onChanged,
    this.pickFile,
  });

  final String path;
  final ValueChanged<String> onChanged;
  final Future<String?> Function()? pickFile;

  @override
  Widget build(BuildContext context) => KeSection(
    title: 'Chat template',
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          KeButton(
            path.isEmpty ? 'Choose .jinja file…' : p.basename(path),
            onPressed: () async {
              final String? selected;
              if (pickFile != null) {
                selected = await pickFile!();
              } else {
                final result = await GuardedPicker.pickFiles(
                  context,
                  category: PickerPrefs.catImport,
                  type: FileType.custom,
                  allowedExtensions: ['jinja'],
                );
                selected = result?.files.single.path;
              }
              if (selected != null) onChanged(selected);
            },
          ),
          if (path.isNotEmpty)
            KeButton('Use embedded template', onPressed: () => onChanged('')),
        ],
      ),
      if (path.isNotEmpty)
        SelectableText(
          path,
          style: keText(
            context,
            size: 12,
            color: AppColors.slateMutedOf(context),
          ),
        ),
      Text(
        'An optional .jinja file overrides the template embedded in the GGUF. '
        'Save the preset, then stop and restart KoboldCpp to apply a template change.',
        style: keText(
          context,
          size: 12,
          color: AppColors.slateFaintOf(context),
        ),
      ),
    ],
  );
}
