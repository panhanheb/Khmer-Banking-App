import 'package:flutter/material.dart';

/// The app's text widget. Use it instead of [Text].
///
/// It is a drop-in replacement for [Text] (same parameters) and follows the
/// theme: colour, font family (Khmer / Latin) and dark mode come from the
/// surrounding [DefaultTextStyle] / [ThemeData.textTheme], exactly like [Text].
///
/// The optional shortcuts ([fontSize], [color], [fontWeight], [lineHeight],
/// [letterSpacing], [decoration]) are applied on top of [style]:
///
/// ```dart
/// AppLabel('totalBalance'.tr, style: theme.textTheme.labelLarge, color: scheme.primary)
/// ```
class AppLabel extends StatelessWidget {
  const AppLabel(
    this.data, {
    super.key,
    this.style,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.lineHeight,
    this.letterSpacing,
    this.decoration,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final TextStyle? style;

  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;

  /// Line height as a multiple of [fontSize] ([TextStyle.height]).
  final double? lineHeight;
  final double? letterSpacing;
  final TextDecoration? decoration;

  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  bool get _hasOverrides =>
      fontSize != null ||
      color != null ||
      fontWeight != null ||
      lineHeight != null ||
      letterSpacing != null ||
      decoration != null;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = _hasOverrides
        ? (style ?? const TextStyle()).copyWith(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            height: lineHeight,
            letterSpacing: letterSpacing,
            decoration: decoration,
          )
        : style;
    return Text(
      data,
      style: effectiveStyle,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
