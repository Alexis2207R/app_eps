import 'package:flutter/material.dart';

@immutable
class ColorsExtension extends ThemeExtension<ColorsExtension> {
  const ColorsExtension({
    required this.secondary,
    required this.standard,
    required this.standardBase,
    required this.standardForeground,
    required this.success,
    required this.successBase,
    required this.successForeground,
    required this.destructive,
    required this.destructiveBase,
    required this.destructiveForeground,
    required this.warning,
    required this.warningBase,
    required this.warningForeground,
    required this.info,
    required this.infoBase,
    required this.infoForeground,
  });

  final Color? secondary;
  final Color? standard;
  final Color? standardBase;
  final Color? standardForeground;
  final Color? success;
  final Color? successBase;
  final Color? successForeground;
  final Color? destructive;
  final Color? destructiveBase;
  final Color? destructiveForeground;
  final Color? warning;
  final Color? warningBase;
  final Color? warningForeground;
  final Color? info;
  final Color? infoBase;
  final Color? infoForeground;

  @override
  ColorsExtension copyWith({
    Color? secondary,
    Color? standard,
    Color? standardBase,
    Color? standardForeground,
    Color? success,
    Color? successBase,
    Color? successForeground,
    Color? destructive,
    Color? destructiveBase,
    Color? destructiveForeground,
    Color? warning,
    Color? warningBase,
    Color? warningForeground,
    Color? info,
    Color? infoBase,
    Color? infoForeground,
  }) {
    return ColorsExtension(
      secondary: secondary ?? this.secondary,
      standard: standard ?? this.standard,
      standardBase: standardBase ?? this.standardBase,
      standardForeground: standardForeground ?? this.standardForeground,
      success: success ?? this.success,
      successBase: successBase ?? this.successBase,
      successForeground: successForeground ?? this.successForeground,
      destructive: destructive ?? this.destructive,
      destructiveBase: destructiveBase ?? this.destructiveBase,
      destructiveForeground: destructiveForeground ?? this.destructiveForeground,
      warning: warning ?? this.warning,
      warningBase: warningBase ?? this.warningBase,
      warningForeground: warningForeground ?? this.warningForeground,
      info: info ?? this.info,
      infoBase: infoBase ?? this.infoBase,
      infoForeground: infoForeground ?? this.infoForeground,
    );
  }

  @override
  ColorsExtension lerp(ColorsExtension? other, double t) {
    if (other is! ColorsExtension) {
      return this;
    }
    return ColorsExtension(
      secondary: Color.lerp(secondary, other.secondary, t),
      standard: Color.lerp(standard, other.standard, t),
      standardBase: Color.lerp(standardBase, other.standardBase, t),
      standardForeground: Color.lerp(standardForeground, other.standardForeground, t),
      success: Color.lerp(success, other.success, t),
      successBase: Color.lerp(successBase, other.successBase, t),
      successForeground: Color.lerp(successForeground, other.successForeground, t),
      destructive: Color.lerp(destructive, other.destructive, t),
      destructiveBase: Color.lerp(destructiveBase, other.destructiveBase, t),
      destructiveForeground: Color.lerp(destructiveForeground, other.destructiveForeground, t),
      warning: Color.lerp(warning, other.warning, t),
      warningBase: Color.lerp(warningBase, other.warningBase, t),
      warningForeground: Color.lerp(warningForeground, other.warningForeground, t),
      info: Color.lerp(info, other.info, t),
      infoBase: Color.lerp(infoBase, other.infoBase, t),
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t),
    );
  }
}
