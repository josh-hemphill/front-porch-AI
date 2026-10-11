// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:front_porch_ai/services/image_prompt/image_prompt.dart';

class ExpressionIntensityPicker extends StatelessWidget {
  const ExpressionIntensityPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final ExpressionIntensity value;
  final ValueChanged<ExpressionIntensity>? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Expression intensity'),
      DropdownButton<ExpressionIntensity>(
        value: value,
        isExpanded: true,
        items: [
          for (final level in ExpressionIntensity.values)
            DropdownMenuItem(value: level, child: Text(level.label)),
        ],
        onChanged: onChanged == null
            ? null
            : (level) {
                if (level != null) onChanged!(level);
              },
      ),
      const Text(
        'Changes the expression wording, not CFG or noise. Results depend on the model.',
      ),
    ],
  );
}
