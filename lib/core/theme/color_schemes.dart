import 'package:flutter/material.dart';

/// Cor semente do app (baseada na identidade visual)
const Color seedColor = Color(0xFF10B981); // Emerald/Verde do app

/// Gera ColorScheme claro automaticamente usando Material 3
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light,
);

/// Gera ColorScheme escuro automaticamente usando Material 3
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.dark,
);
