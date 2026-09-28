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

const kComfyLinkTypes = {
  'MODEL',
  'CLIP',
  'VAE',
  'LATENT',
  'CONDITIONING',
  'IMAGE',
  'MASK',
  'CONTROL_NET',
  'GUIDER',
  'NOISE',
  'SAMPLER',
  'SIGMAS',
};

/// Stable widget order for built-in nodes, including their nested widgets.
const kComfyFallbackWidgets = <String, List<String>>{
  'UNETLoader': ['unet_name', 'weight_dtype'],
  'UnetLoaderGGUF': ['unet_name'],
  'UnetLoaderGGUFAdvanced': [
    'unet_name',
    'dequant_dtype',
    'patch_dtype',
    'patch_on_device',
  ],
  'CLIPLoader': ['clip_name', 'type', 'device'],
  'CLIPLoaderGGUF': ['clip_name', 'type'],
  'DualCLIPLoaderGGUF': ['clip_name1', 'clip_name2', 'type'],
  'TripleCLIPLoaderGGUF': ['clip_name1', 'clip_name2', 'clip_name3'],
  'QuadrupleCLIPLoaderGGUF': [
    'clip_name1',
    'clip_name2',
    'clip_name3',
    'clip_name4',
  ],
  'DualCLIPLoader': ['clip_name1', 'clip_name2', 'type', 'device'],
  'VAELoader': ['vae_name'],
  'CheckpointLoaderSimple': ['ckpt_name'],
  'CLIPTextEncode': ['text'],
  'KSampler': ['seed', 'steps', 'cfg', 'sampler_name', 'scheduler', 'denoise'],
  'EmptyLatentImage': ['width', 'height', 'batch_size'],
  'EmptySD3LatentImage': ['width', 'height', 'batch_size'],
  'ModelSamplingAuraFlow': ['shift'],
  'FluxGuidance': ['guidance'],
  'CFGNorm': ['strength'],
  'LoraLoader': ['lora_name', 'strength_model', 'strength_clip'],
  'SaveImage': ['filename_prefix'],
  'LoadImage': ['image'],
  'TextEncodeQwenImageEditPlus': ['prompt'],
  'TextEncodeQwenImage21': ['prompt', 'negative_prompt', 'resolution'],
  'TextGenerate': [
    'prompt',
    'max_length',
    'sampling_mode',
    'sampling_mode.temperature',
    'sampling_mode.top_k',
    'sampling_mode.top_p',
    'sampling_mode.min_p',
    'sampling_mode.repetition_penalty',
    'sampling_mode.presence_penalty',
    'sampling_mode.seed',
    'thinking',
    'use_default_template',
    'mtp',
  ],
  'ComfySwitchNode': ['switch'],
  'PrimitiveStringMultiline': ['value'],
  'QwenImage21Cache': ['device', 'dtype'],
  'ResolutionSelector': ['aspect_ratio', 'megapixels', 'multiple'],
  'SaveImageAdvanced': [
    'filename_prefix',
    'format',
    'format.bit_depth',
    'format.input_color_space',
  ],
};

List<String> comfyWidgetInputNames(
  Map<String, dynamic>? objectInfo,
  String type, {
  List<Object?> widgets = const [],
}) {
  final fallback = kComfyFallbackWidgets[type];
  if (fallback != null) return fallback;
  return _widgetNamesFromObjectInfo(objectInfo, type, widgets);
}

List<String> _widgetNamesFromObjectInfo(
  Map<String, dynamic>? info,
  String type,
  List<Object?> widgets,
) {
  final node = info?[type];
  if (node is! Map || node['input'] is! Map) return const [];
  final names = <String>[];
  var widgetIndex = 0;

  void addSection(Map sections, String prefix) {
    for (final sectionName in ['required', 'optional']) {
      final section = sections[sectionName];
      if (section is! Map) continue;
      for (final entry in section.entries) {
        final spec = entry.value;
        if (!_isWidgetSpec(spec)) continue;
        final name = prefix.isEmpty
            ? entry.key.toString()
            : '$prefix.${entry.key}';
        names.add(name);
        final selected = widgetIndex < widgets.length
            ? widgets[widgetIndex]
            : null;
        widgetIndex++;
        if (spec[0] != 'COMFY_DYNAMICCOMBO_V3' || spec.length < 2) {
          continue;
        }
        final meta = spec[1];
        final options = meta is Map ? meta['options'] : null;
        if (options is! List) continue;
        for (final option in options) {
          if (option is Map && option['key'] == selected) {
            final nested = option['inputs'];
            if (nested is Map) addSection(nested, name);
            break;
          }
        }
      }
    }
  }

  addSection(node['input'] as Map, '');
  return names;
}

bool _isWidgetSpec(Object? spec) {
  if (spec is! List || spec.isEmpty) return false;
  final first = spec.first;
  if (first is List) return true;
  if (first is! String || first == 'COMFY_AUTOGROW_V3') return false;
  if (kComfyLinkTypes.contains(first)) return false;
  final meta = spec.length > 1 ? spec[1] : null;
  return meta is! Map || meta['socketless'] != true;
}
