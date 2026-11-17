import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../tokens/nsl_tokens.dart';
import '../tokens/style_tokens.dart';
import 'adjust.dart';
import 'component_metrics.dart';
import 'nsl_theme.dart';

/// สร้าง [ThemeData] ของ Material จาก token ของ NSL — ทุกค่ามาจาก token (สี, มุมโค้ง, ความหนาแน่น, ฟอนต์, เงา)
///
/// ทำไมต้องมี : แอปเขียน `buildTheme` เองสั้น ๆ (แต่งแค่ dialog/ปุ่ม/snackbar) ส่วน Switch, Checkbox, Chip, Slider,
/// ListTile ฯลฯ ได้สีจาก `ColorScheme.fromSeed` ซึ่งเพี้ยนจากสีแบรนด์ — ตัวสร้างนี้กำหนด [ColorScheme] เองครบ
/// และแต่งตัวควบคุมเหล่านั้นให้ตรงกับ [NslButton] และ component อื่นของ nsl_ui
///
/// - แนบ [NslTheme] ไว้ใน `extensions` → `context.nsl` ใช้ได้ทันทีโดยไม่ต้องครอบ [NslThemeScope]
/// - [platform] ใช้ตัดสินจอสัมผัส (พื้นที่แตะ ≥ 44) ; ไม่ระบุ = `defaultTargetPlatform`
/// - ตัวอักษรที่วางบนพื้นสี (ปุ่ม, ชิปที่เลือก, snackbar) ผ่าน [NslComponentMetrics.legibleOn] เสมอ
/// - ไม่รวม `minSize` ของตัวอักษร (ใช้ได้เฉพาะ component ของ nsl_ui ผ่าน `textStyle`) และไม่แตะตัวอักษรบนแคนวาส
ThemeData buildNslThemeData(NslTokens t, {TargetPlatform? platform}) {
  final c = t.colors;
  final b = t.brightness;
  final p = platform ?? defaultTargetPlatform;
  final touch = p == TargetPlatform.android || p == TargetPlatform.iOS || p == TargetPlatform.fuchsia;

  final onPrimary = t.legibleOn(c.onAccent, c.accent);
  final accentOnSurface = t.legibleOn(c.accentInk, c.surface);
  final accentOnSelected = t.legibleOn(c.accentInk, c.selected);
  final inverseText = t.legibleOn(c.bg, c.text);

  BorderRadius r(double v) => BorderRadius.circular(v);
  RoundedRectangleBorder shape(double radius, {BorderSide side = BorderSide.none}) => RoundedRectangleBorder(borderRadius: r(radius), side: side);
  double elev(double base) => t.elevation.mode == NslElevationMode.flat ? 0 : base * t.elevation.strength;

  final scheme = ColorScheme(
    brightness: b,
    primary: c.accent,
    onPrimary: onPrimary,
    primaryContainer: c.accentTint,
    onPrimaryContainer: t.legibleOn(c.accentInk, c.accentTint),
    secondary: c.accent,
    onSecondary: onPrimary,
    secondaryContainer: c.selected,
    onSecondaryContainer: accentOnSelected,
    error: c.danger,
    onError: t.legibleOn(c.onAccent, c.danger),
    errorContainer: c.dangerBg,
    onErrorContainer: c.dangerText,
    surface: c.surface,
    onSurface: c.text,
    onSurfaceVariant: c.textMuted,
    outline: c.borderStrong,
    outlineVariant: c.border,
    shadow: c.shadow,
    inverseSurface: c.text,
    onInverseSurface: inverseText,
    inversePrimary: c.accentTint,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.bg,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainerHighest: c.surfaceSunken,
  );

  // ตัวอักษรหลัก : ฟอนต์/สี/ขนาดจากธีม (ขนาดคูณ scale)
  final typo = Typography.material2021(platform: p);
  final baseText = (t.isDark ? typo.white : typo.black).merge(typo.englishLike).apply(
        fontFamily: t.type.effectiveFamily,
        fontFamilyFallback: t.type.fallback,
        bodyColor: c.text,
        displayColor: c.text,
      );
  final textTheme = scaleTextTheme(baseText, t.type.scale);

  final controlH = t.controlHeight(touch: touch);
  final buttonPad = EdgeInsets.symmetric(horizontal: t.gap * 2);
  final buttonShape = shape(t.shape.md);
  final buttonText = t.textStyle(14, weight: FontWeight.w600);

  Color? onState(Set<WidgetState> s, {Color? disabled, Color? selected, required Color normal}) {
    if (s.contains(WidgetState.disabled)) return disabled ?? c.textFaint;
    if (s.contains(WidgetState.selected)) return selected ?? normal;
    return normal;
  }

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.surface,
    cardColor: c.surface,
    dividerColor: c.borderSoft,
    hoverColor: c.hover,
    focusColor: c.hover,
    splashColor: c.accent.withValues(alpha: 0.12),
    highlightColor: c.hover,
    fontFamily: t.type.effectiveFamily,
    fontFamilyFallback: t.type.fallback,
    textTheme: textTheme,
    platform: p,
    visualDensity: t.visualDensityFor(touch: touch),
    // กำหนดชัดแทนปล่อยตามแพลตฟอร์ม : จอสัมผัส = เผื่อพื้นที่แตะ (48) ; เดสก์ท็อป = ขนาดตามที่ธีมกำหนด (ความสูงปุ่ม = controlHeight)
    materialTapTargetSize: touch ? MaterialTapTargetSize.padded : MaterialTapTargetSize.shrinkWrap,
    iconTheme: IconThemeData(color: c.icon),
    extensions: [NslTheme(t)],
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: t.textStyle(18, weight: FontWeight.w600, color: c.text),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: shape(t.shape.lg, side: BorderSide(color: c.borderSoft)),
    ),
    dividerTheme: DividerThemeData(color: c.borderSoft, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: elev(12),
      shadowColor: c.shadow,
      shape: shape(t.shape.lg, side: BorderSide(color: c.borderSoft)),
      titleTextStyle: t.textStyle(18, weight: FontWeight.w600, color: c.text),
      contentTextStyle: t.textStyle(14, color: c.text, height: 1.5),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: elev(8),
      shadowColor: c.shadow,
      shape: shape(t.shape.md, side: BorderSide(color: c.borderSoft)),
      textStyle: t.textStyle(14, color: c.text),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surfaceRaised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(elev(8)),
        shape: WidgetStatePropertyAll(shape(t.shape.md, side: BorderSide(color: c.borderSoft))),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: elev(8),
      shadowColor: c.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(t.shape.xl))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.text,
      contentTextStyle: t.textStyle(14, color: inverseText),
      actionTextColor: t.legibleOn(c.accentTint, c.text),
      behavior: SnackBarBehavior.floating,
      shape: shape(t.shape.md),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.text, borderRadius: r(t.shape.sm)),
      textStyle: t.textStyle(12, color: inverseText),
      padding: EdgeInsets.symmetric(horizontal: t.gap, vertical: t.gap / 2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: t.density == NslDensity.compact,
      filled: true,
      fillColor: c.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: t.gap * 1.5, vertical: t.gap * 1.25),
      hintStyle: t.textStyle(14, color: c.textMuted),
      labelStyle: t.textStyle(14, color: c.textMuted),
      helperStyle: t.textStyle(12, color: c.textMuted),
      errorStyle: t.textStyle(12, color: c.dangerText),
      border: OutlineInputBorder(borderRadius: r(t.shape.md), borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(borderRadius: r(t.shape.md), borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(borderRadius: r(t.shape.md), borderSide: BorderSide(color: c.accent, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: r(t.shape.md), borderSide: BorderSide(color: c.danger)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: r(t.shape.md), borderSide: BorderSide(color: c.danger, width: 2)),
      disabledBorder: OutlineInputBorder(borderRadius: r(t.shape.md), borderSide: BorderSide(color: c.borderSoft)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: onPrimary,
        disabledBackgroundColor: c.surfaceSunken,
        disabledForegroundColor: c.textFaint,
        minimumSize: Size(0, controlH),
        padding: buttonPad,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.surfaceRaised,
        foregroundColor: c.text,
        disabledBackgroundColor: c.surfaceSunken,
        disabledForegroundColor: c.textFaint,
        surfaceTintColor: Colors.transparent,
        shadowColor: c.shadow,
        elevation: elev(1),
        minimumSize: Size(0, controlH),
        padding: buttonPad,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        disabledForegroundColor: c.textFaint,
        side: BorderSide(color: c.borderStrong),
        minimumSize: Size(0, controlH),
        padding: buttonPad,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentOnSurface,
        disabledForegroundColor: c.textFaint,
        minimumSize: Size(0, controlH),
        padding: buttonPad,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.icon,
        disabledForegroundColor: c.textFaint,
        minimumSize: Size.square(controlH),
        shape: shape(t.shape.sm),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => onState(s, selected: onPrimary, normal: c.textMuted)),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return c.surfaceSunken;
        return s.contains(WidgetState.selected) ? c.accent : c.surfaceSunken;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return Colors.transparent;
        return s.contains(WidgetState.disabled) ? c.borderSoft : c.borderStrong;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return s.contains(WidgetState.selected) ? c.textFaint : Colors.transparent;
        return s.contains(WidgetState.selected) ? c.accent : Colors.transparent;
      }),
      checkColor: WidgetStatePropertyAll(onPrimary),
      side: WidgetStateBorderSide.resolveWith((s) => BorderSide(
            color: s.contains(WidgetState.disabled) ? c.borderSoft : (s.contains(WidgetState.selected) ? c.accent : c.borderStrong),
            width: 1.5,
          )),
      shape: shape(t.shape.xs),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return c.textFaint;
        return s.contains(WidgetState.selected) ? c.accent : c.borderStrong;
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.selected,
      disabledColor: c.surfaceSunken,
      surfaceTintColor: Colors.transparent,
      checkmarkColor: accentOnSelected,
      side: BorderSide(color: c.border),
      shape: shape(t.shape.pill),
      padding: EdgeInsets.symmetric(horizontal: t.gap / 2),
      labelStyle: t.textStyle(13).copyWith(
            color: WidgetStateColor.resolveWith((s) => onState(s, selected: accentOnSelected, normal: c.text)!),
          ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.selected : Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((s) => onState(s, selected: accentOnSelected, normal: c.text)),
        side: WidgetStateBorderSide.resolveWith((s) => BorderSide(color: s.contains(WidgetState.selected) ? c.accentBorder : c.borderStrong)),
        shape: WidgetStatePropertyAll(buttonShape),
        minimumSize: WidgetStatePropertyAll(Size(0, controlH)),
        textStyle: WidgetStatePropertyAll(t.textStyle(14, weight: FontWeight.w500)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.accent,
      inactiveTrackColor: c.border,
      disabledActiveTrackColor: c.textFaint,
      disabledInactiveTrackColor: c.borderSoft,
      thumbColor: c.accent,
      disabledThumbColor: c.textFaint,
      overlayColor: c.accent.withValues(alpha: 0.12),
      trackHeight: 4,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.border, circularTrackColor: c.border),
    listTileTheme: ListTileThemeData(
      selectedTileColor: c.selected,
      selectedColor: accentOnSelected,
      iconColor: c.icon,
      textColor: c.text,
      titleTextStyle: t.textStyle(15, color: c.text),
      subtitleTextStyle: t.textStyle(13, color: c.textMuted),
      shape: shape(t.shape.md),
      contentPadding: EdgeInsets.symmetric(horizontal: t.gap * 2),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: c.accent,
      labelColor: c.text,
      unselectedLabelColor: c.textMuted,
      dividerColor: c.borderSoft,
      labelStyle: t.textStyle(14, weight: FontWeight.w600),
      unselectedLabelStyle: t.textStyle(14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: c.selected,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? accentOnSelected : c.icon)),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => t.textStyle(12, weight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400, color: s.contains(WidgetState.selected) ? c.text : c.textMuted),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(c.borderStrong),
      radius: Radius.circular(t.shape.pill),
      thickness: const WidgetStatePropertyAll(8),
    ),
  );
}
