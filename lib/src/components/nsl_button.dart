import 'package:flutter/material.dart';

import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';
import 'pressable.dart';

/// ชนิดของปุ่ม
enum NslButtonKind {
  /// การกระทำหลัก — พื้น accent
  primary,

  /// การกระทำรอง — พื้น surface มีขอบ
  secondary,

  /// การลบ/ย้อนไม่ได้
  danger,

  /// ไม่มีพื้นและขอบ (เมนู/แถบเครื่องมือ)
  ghost,
}

/// ปุ่มมาตรฐานของ NSL — สี มุมโค้ง ขนาด ตัวอักษร มาจาก token ทั้งหมด จึงเปลี่ยนตามธีมและ density
///
/// [onPressed] เป็น null = ปิดใช้งาน ; [semanticLabel] ไม่ระบุ = ใช้ [label]
class NslButton extends StatelessWidget {
  const NslButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = NslButtonKind.secondary,
    this.icon,
    this.semanticLabel,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final NslButtonKind kind;
  final IconData? icon;
  final String? semanticLabel;

  /// true = ขยายเต็มความกว้างที่ได้
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final enabled = onPressed != null;
    final (bg, fg, border, weight) = switch (kind) {
      NslButtonKind.primary => (c.accent, t.legibleOn(c.onAccent, c.accent), c.accent, FontWeight.w600),
      NslButtonKind.secondary => (c.surface, c.text, c.borderStrong, FontWeight.w500),
      NslButtonKind.danger => (c.dangerBg, c.dangerText, c.danger.withValues(alpha: 0.5), FontWeight.w500),
      NslButtonKind.ghost => (Colors.transparent, c.text, null, FontWeight.w500),
    };
    final fgNow = enabled ? fg : c.textFaint;
    final bgNow = enabled ? bg : (kind == NslButtonKind.ghost ? Colors.transparent : c.surfaceSunken);
    final borderNow = enabled ? border : (kind == NslButtonKind.ghost ? null : c.borderSoft);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: t.type.fit(18), color: fgNow), SizedBox(width: t.gap)],
        Flexible(
          child: Text(label, style: t.textStyle(14, weight: weight, color: fgNow), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    return NslPressable(
      onTap: onPressed,
      radius: t.shape.md,
      background: bgNow,
      border: borderNow,
      overlay: fgNow.withValues(alpha: 0.10),
      // วงโฟกัส : ปุ่ม primary พื้นเป็น accent อยู่แล้ว จึงใช้สีตัวอักษรเพื่อให้เห็น
      ring: kind == NslButtonKind.primary ? c.text : c.accent,
      semanticLabel: semanticLabel ?? label,
      minHeight: t.controlHeight(touch: context.nslTouch),
      padding: EdgeInsets.symmetric(horizontal: t.gap * 2),
      child: content,
    );
  }
}
