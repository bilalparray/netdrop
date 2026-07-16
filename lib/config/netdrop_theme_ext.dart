import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';

@immutable
class NetDropSemanticColors extends ThemeExtension<NetDropSemanticColors> {
  const NetDropSemanticColors({
    required this.surfaceMuted,
    required this.cardShadow,
    required this.border,
    required this.textSecondary,
    required this.textMuted,
    required this.progressTrack,
  });

  final Color surfaceMuted;
  final Color cardShadow;
  final Color border;
  final Color textSecondary;
  final Color textMuted;
  final Color progressTrack;

  static const light = NetDropSemanticColors(
    surfaceMuted: NetDropColors.surfaceMuted,
    cardShadow: NetDropColors.cardShadow,
    border: NetDropColors.surfaceMuted,
    textSecondary: NetDropColors.textSecondary,
    textMuted: NetDropColors.textMuted,
    progressTrack: NetDropColors.surfaceMuted,
  );

  static const dark = NetDropSemanticColors(
    surfaceMuted: Color(0xFF243044),
    cardShadow: Color(0x50000000),
    border: Color(0xFF2D3A4F),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    progressTrack: Color(0xFF2D3A4F),
  );

  static NetDropSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<NetDropSemanticColors>() ?? light;
  }

  @override
  NetDropSemanticColors copyWith({
    Color? surfaceMuted,
    Color? cardShadow,
    Color? border,
    Color? textSecondary,
    Color? textMuted,
    Color? progressTrack,
  }) {
    return NetDropSemanticColors(
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      cardShadow: cardShadow ?? this.cardShadow,
      border: border ?? this.border,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      progressTrack: progressTrack ?? this.progressTrack,
    );
  }

  @override
  NetDropSemanticColors lerp(covariant ThemeExtension<NetDropSemanticColors>? other, double t) {
    if (other is! NetDropSemanticColors) {
      return this;
    }
    return NetDropSemanticColors(
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
    );
  }
}

extension NetDropThemeX on BuildContext {
  NetDropSemanticColors get nd => NetDropSemanticColors.of(this);
  ColorScheme get cs => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
