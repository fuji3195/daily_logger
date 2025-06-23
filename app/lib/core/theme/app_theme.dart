import 'package:flutter/material.dart';

class AppTheme {
  static final _seed = const Color(0xFF0061FF);

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
  );
}
