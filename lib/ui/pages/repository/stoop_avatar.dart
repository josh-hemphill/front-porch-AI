// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/providers/auth_state.dart';
import 'package:front_porch_ai/services/backporch/backporch.dart';
import 'package:front_porch_ai/ui/pages/repository/stoop_glass.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// Loads a Stoop card asset (avatar) by id. The asset endpoint serves only
/// signed-in users, so the request carries the access token as a Bearer header.
/// Falls back to a neutral placeholder while loading or on error.
///
/// Crops anchor to the top like the hub (`object-position: center top`):
/// card art is portrait, and a centred crop in a square box takes the head.
class StoopAvatar extends StatelessWidget {
  final String? assetId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  const StoopAvatar({
    super.key,
    required this.assetId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthState>().accessToken;
    final id = assetId;
    if (id == null || id.isEmpty || token == null) return _placeholder(context);
    return Image.network(
      BackporchApi().assetUrl(id),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      headers: {'Authorization': 'Bearer $token'},
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _placeholder(context),
      // frame is null until the first decoded frame — including the window
      // before the first byte, where loadingBuilder's progress is also null
      // and a natural-height image would lay out at zero height.
      frameBuilder: (context, child, frame, _) =>
          frame == null ? _placeholder(context, loading: true) : child,
    );
  }

  // Hub placeholder: a faint lantern on the inset ground (.hub-tile-art).
  // With no height of its own (natural-height art, e.g. the detail page) it
  // holds a portrait box so the layout does not collapse while loading;
  // under a tight box (tiles) AspectRatio just fills it.
  Widget _placeholder(BuildContext context, {bool loading = false}) {
    final box = Container(
      width: width,
      height: height,
      color: stoopBg1(context),
      alignment: Alignment.center,
      child: _placeholderMark(loading),
    );
    return height == null ? AspectRatio(aspectRatio: 3 / 4, child: box) : box;
  }

  Widget _placeholderMark(bool loading) {
    return loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.stoopAmber,
            ),
          )
        : const Opacity(
            opacity: 0.35,
            child: Text('🏮', style: TextStyle(fontSize: 30)),
          );
  }
}
