import 'package:flutter/material.dart';

import '../theme/adjust.dart';
import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';
import 'pressable.dart';

/// ชนิดของปุ่ม
enum NslButtonKind {
  /// การกระทำหลัก — พื้น accent
  primary,

  /// การกระทำรอง — พื้น surface มีขอบ
  secondary,

  /// การลบ/ย้อนไม่ได้ (พื้นแดงอ่อน ; ใช้ `outline` ได้)
  danger,

  /// ไม่มีพื้นและขอบ (เมนู/แถบเครื่องมือ)
  ghost,

  /// สำเร็จ/ยืนยัน — พื้นสี success (เพิ่มใน 1.1 หลังปล่อยชุดแรก)
  success,

  /// เตือน — พื้นสี warn
  warning,

  /// ข้อมูล — พื้นสี info
  info,

  /// ลิงก์ — ตัวอักษร accent ขีดเส้นใต้ ไม่มีพื้น/ขอบ/ระยะขอบ
  link,
}

/// ขนาดของปุ่ม (ความสูงมาตรฐานมาจาก density ; บนจอสัมผัสทุกขนาดสูงไม่ต่ำกว่า 44)
enum NslButtonSize { sm, md, lg }

/// ปุ่มมาตรฐานของ NSL — สี มุมโค้ง ขนาด ตัวอักษร มาจาก token ทั้งหมด จึงเปลี่ยนตามธีมและ density
///
/// - [onPressed] เป็น null = ปิดใช้งาน ; [semanticLabel] ไม่ระบุ = ใช้ [label]
/// - [size] : `sm` ≈ 80% / `md` / `lg` ≈ 120% ของความสูงมาตรฐาน (ตัวอักษร 13 / 14 / 16)
/// - [outline] : ไม่มีพื้น มีขอบและตัวอักษรสีของชนิดนั้น (ใช้กับ primary/danger/success/warning/info)
/// - [loading] : แสดงวงหมุนแทนไอคอน และกดไม่ได้ (ไม่เทาลง) ; ใช้ระหว่างรอผลของการกระทำ
class NslButton extends StatelessWidget {
  const NslButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = NslButtonKind.secondary,
    this.icon,
    this.semanticLabel,
    this.expand = false,
    this.size = NslButtonSize.md,
    this.outline = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final NslButtonKind kind;
  final IconData? icon;
  final String? semanticLabel;

  /// true = ขยายเต็มความกว้างที่ได้
  final bool expand;
  final NslButtonSize size;
  final bool outline;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final touch = context.nslTouch;
    final enabled = onPressed != null;

    // สีหลักของชนิด (ใช้เป็นพื้นแบบทึบ หรือขอบ/ตัวอักษรแบบ outline)
    final Color? base = switch (kind) {
      NslButtonKind.primary => c.accent,
      NslButtonKind.danger => c.danger,
      NslButtonKind.success => c.success,
      NslButtonKind.warning => c.warnText,
      NslButtonKind.info => c.infoText,
      _ => null,
    };
    final solid = base != null && !outline && kind != NslButtonKind.danger;
    final (bg, fg, border, weight) = switch (kind) {
      NslButtonKind.secondary => (c.surface, c.text, c.borderStrong, FontWeight.w500),
      NslButtonKind.ghost => (Colors.transparent, c.text, null, FontWeight.w500),
      NslButtonKind.link => (Colors.transparent, t.legibleOn(c.accentInk, c.surface), null, FontWeight.w500),
      NslButtonKind.danger when !outline => (c.dangerBg, c.dangerText, c.danger.withValues(alpha: 0.5), FontWeight.w500),
      _ when solid => (base, t.legibleOn(c.onAccent, base), base, FontWeight.w600),
      // outline : พื้นโปร่ง ขอบสีของชนิด ตัวอักษรสีเดียวกัน (ปรับให้อ่านออกบนพื้นผิว)
      _ => (Colors.transparent, t.legibleOn(base!, c.surface), base, FontWeight.w600),
    };
    final isGhostLike = bg == Colors.transparent && border == null;
    final fgNow = enabled || loading ? fg : c.textFaint;
    final bgNow = enabled || loading ? bg : (isGhostLike ? Colors.transparent : c.surfaceSunken);
    final borderNow = enabled || loading ? border : (isGhostLike ? null : c.borderSoft);

    final base0 = t.controlHeight(touch: touch);
    final (heightF, fontSize, iconSize, padF) = switch (size) {
      NslButtonSize.sm => (0.8, 13.0, 16.0, 1.5),
      NslButtonSize.md => (1.0, 14.0, 18.0, 2.0),
      NslButtonSize.lg => (1.2, 16.0, 20.0, 2.5),
    };
    final minHeight = touch ? (base0 * heightF < kMinTapTarget ? kMinTapTarget : base0 * heightF) : base0 * heightF;

    final lead = loading
        ? SizedBox(width: t.type.fit(iconSize - 2), height: t.type.fit(iconSize - 2), child: CircularProgressIndicator(strokeWidth: 2, color: fgNow))
        : (icon != null ? Icon(icon, size: t.type.fit(iconSize), color: fgNow) : null);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (lead != null) ...[lead, SizedBox(width: t.gap)],
        Flexible(
          child: Text(
            label,
            style: t.textStyle(fontSize, weight: weight, color: fgNow).copyWith(decoration: kind == NslButtonKind.link ? TextDecoration.underline : null, decorationColor: fgNow),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return NslPressable(
      onTap: loading ? null : onPressed,
      radius: t.shape.md,
      background: bgNow,
      border: borderNow,
      overlay: fgNow.withValues(alpha: 0.10),
      // วงโฟกัส : พื้นทึบสี accent/success ฯลฯ ใช้สีตัวอักษรเพื่อให้เห็น
      ring: solid ? c.text : c.accent,
      semanticLabel: semanticLabel ?? label,
      minHeight: minHeight,
      padding: kind == NslButtonKind.link ? EdgeInsets.symmetric(horizontal: t.gap) : EdgeInsets.symmetric(horizontal: t.gap * padF),
      child: content,
    );
  }
}
