import 'package:flutter/material.dart';

/// Renk tokenları (şartname §1.2).
abstract final class K {
  static const navy = Color(0xFF231A57);
  static const violet7 = Color(0xFF5338B7);
  static const violet5 = Color(0xFF825AE6);
  static const sky = Color(0xFF44C9F8);
  static const aqua = Color(0xFF35D9C9);
  static const sun = Color(0xFFFFD343);
  static const orange = Color(0xFFFF9330);
  static const pink = Color(0xFFF57FCE);
  static const paper = Color(0xFFFFF8FF);
  static const ink = Color(0xFF20173D);
  static const error = Color(0xFFD94962);
  static const lilac = Color(0xFFC9B8FF);
  static const deep = Color(0xFF160F3B);
  static const btnViolet = Color(0xFF6446D0);

  static Color edge(Color c) => Color.lerp(c, const Color(0xFF1A0F3A), .32)!;
  static const answer = [sun, aqua, pink, sky];
}

/// Baloo 2 (başlık) + Nunito (gövde); ikisi de değişken font, Türkçe karakter destekli.
abstract final class T {
  static TextStyle display(double size, {Color color = K.paper, double w = 800, double height = 1.1}) => TextStyle(
        fontFamily: 'Baloo2',
        fontSize: size,
        height: height,
        color: color,
        fontWeight: _fw(w),
        fontVariations: [FontVariation('wght', w)],
      );
  static TextStyle body(double size, {Color color = K.paper, double w = 700, double height = 1.35}) => TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        height: height,
        color: color,
        fontWeight: _fw(w),
        fontVariations: [FontVariation('wght', w)],
      );
  static FontWeight _fw(double w) => FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: K.navy,
      fontFamily: 'Nunito',
      colorScheme: const ColorScheme.dark(primary: K.sun, secondary: K.violet5, surface: K.navy, error: K.error),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

/// Derleme sürümü (tool/build_web.sh git kısa özetini --dart-define=SURUM ile verir).
const kSurum = String.fromEnvironment('SURUM', defaultValue: 'yerel');
const kSurumEtiketi = 'Sürüm 0.1 · $kSurum';
