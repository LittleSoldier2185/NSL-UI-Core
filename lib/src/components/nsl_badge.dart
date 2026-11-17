import 'package:flutter/material.dart';

import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';

/// โทนของป้าย — แต่ละโทนใช้คู่สีที่ core รับประกัน contrast ≥ 4.5 (`*Text/*Bg`, `textMuted/surface`)
enum NslBadgeTone { neutral, success, info, warn, danger, accent }

/// ป้ายสถานะขนาดเล็ก (มุมกลม) — ข้อความสั้น ๆ เช่น "พร้อมใช้", "ผิดพลาด"
///
/// สถานะต้องไม่สื่อด้วยสีอย่างเดียว : ใส่ [icon] หรือข้อความที่บอกความหมายเสมอ
class NslBadge extends StatelessWidget {
  const NslBadge(
    this.label, {
    super.key,
    this.tone = NslBadgeTone.neutral,
    this.icon,
    this.background,
    this.foreground,
  });

  final String label;
  final NslBadgeTone tone;
  final IconData? icon;

  /// สีพื้นเฉพาะแอป (เช่น คู่สีสถานะของ Lyra) — ระบุแล้วแทนสีของ [tone] ; ตัวอักษรถูกปรับให้ผ่าน contrast 4.5:1 เสมอ
  /// (พื้นโปร่งผสมบนสีพื้นผิวก่อนวัด) จึงใส่สีอะไรก็อ่านออก — ถ้าไม่ระบุ [foreground] ใช้สีตัวอักษรหลัก
  final Color? background;

  /// สีตัวอักษรที่ต้องการ (ใช้เมื่อมี [background]) — ถ้าไม่ผ่าน 4.5:1 จะถูกขยับให้ผ่าน
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final custom = background;
    final (bg, fg, border) = custom != null
        ? (custom, t.legibleOn(foreground ?? c.text, custom), null)
        : switch (tone) {
            NslBadgeTone.neutral => (c.surface, c.textMuted, c.border),
            NslBadgeTone.success => (c.successBg, c.successText, null),
            NslBadgeTone.info => (c.infoBg, c.infoText, null),
            NslBadgeTone.warn => (c.warnBg, c.warnText, null),
            NslBadgeTone.danger => (c.dangerBg, c.dangerText, null),
            NslBadgeTone.accent => (
              c.accentTint,
              t.legibleOn(c.accentInk, c.accentTint),
              null,
            ),
          };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: t.gap * 1.25,
          vertical: t.gap / 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(t.shape.pill),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: t.type.fit(14), color: fg),
              SizedBox(width: t.gap / 2),
            ],
            Flexible(
              child: Text(
                label,
                style: t.textStyle(12, weight: FontWeight.w500, color: fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
