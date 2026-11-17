import 'package:flutter/material.dart';

import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';
import 'pressable.dart';

/// ตัวเลือกในเมนูนำทาง (แถบข้าง/แถบล่าง) : ไอคอน + ป้ายชื่อ + ป้ายตัวเลข (ถ้ามี) + สถานะเลือกอยู่
///
/// - [collapsed] = true : แสดงเฉพาะไอคอน (แถบข้างแบบย่อ) พร้อม tooltip และชื่อสำหรับโปรแกรมอ่านหน้าจอ
/// - [badge] > 0 : แสดงเป็นเลขในป้ายกลม (เกิน 99 แสดง `99+`) และรวมในชื่อสำหรับโปรแกรมอ่านหน้าจอ
/// ใช้ในพื้นที่ที่ความกว้างจำกัด (แถบข้าง) — จะขยายเต็มความกว้างที่ได้เมื่อไม่ย่อ
///
/// ขีดจำกัดความกว้าง (แบบเต็มที่มีป้ายเลข `99+` ; วัดจริง) : ส่วนที่ไม่ยืดหด (ไอคอน + ป้ายเลข + ระยะขอบ) ต้องพอดี
/// — ตัวอักษรปกติ ≈ 99 (compact) / 113 (normal) / 127 (comfortable) px ; ตัวอักษรขยายสุด (ธีม 1.2 × ระบบ 1.5)
/// ≈ 132 / 146 / 160 px ; ป้ายชื่อเป็นส่วนที่หดและตัดด้วย … ก่อนเสมอ ; ไม่มีป้ายเลขแคบกว่านี้ได้
class NslNavItem extends StatelessWidget {
  const NslNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.collapsed = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? badge;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final bg = selected ? c.selected : Colors.transparent;
    final fg = selected ? t.legibleOn(c.accentInk, bg) : t.legibleOn(c.icon, bg);
    final labelColor = selected ? fg : t.legibleOn(c.textMuted, bg);
    final h = t.controlHeight(touch: context.nslTouch) + t.gap / 2;
    final hasBadge = (badge ?? 0) > 0;
    final name = hasBadge ? '$label ($badge)' : label;

    final badgeView = !hasBadge
        ? null
        : Container(
            constraints: BoxConstraints(minWidth: t.gap * 2.75),
            padding: EdgeInsets.symmetric(horizontal: t.gap * 0.75, vertical: t.gap / 4),
            decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(t.shape.pill)),
            alignment: Alignment.center,
            child: Text(badge! > 99 ? '99+' : '$badge', style: t.textStyle(12, weight: FontWeight.w600, color: t.legibleOn(c.onAccent, c.accent))),
          );

    final item = NslPressable(
      onTap: onTap,
      radius: t.shape.md,
      background: bg,
      border: selected ? c.accentBorder : null,
      overlay: c.hover,
      ring: c.accent,
      semanticLabel: name,
      selected: selected,
      minHeight: h,
      minWidth: collapsed ? h : 0,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : t.gap * 1.5),
      child: collapsed
          ? Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Icon(icon, size: t.type.fit(20), color: fg),
              if (badgeView != null) Positioned(top: -t.gap / 2, right: -t.gap, child: badgeView),
            ])
          : Row(children: [
              Icon(icon, size: t.type.fit(20), color: fg),
              SizedBox(width: t.gap * 1.5),
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textStyle(14, weight: selected ? FontWeight.w600 : FontWeight.w500, color: labelColor)),
              ),
              if (badgeView != null) ...[SizedBox(width: t.gap), badgeView],
            ]),
    );
    return collapsed ? Tooltip(message: label, excludeFromSemantics: true, child: item) : item;
  }
}
