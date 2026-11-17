import 'package:flutter/material.dart';

import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';
import 'pressable.dart';

/// ปุ่มไอคอนสี่เหลี่ยมจัตุรัส (แถบเครื่องมือ/แถบหัว) — ขนาดตาม density และไม่เล็กกว่า 44 บนจอสัมผัส
///
/// [tooltip] จำเป็น : ใช้เป็นทั้ง tooltip ของเมาส์และชื่อสำหรับโปรแกรมอ่านหน้าจอ (ปุ่มไอคอนไม่มีข้อความ)
class NslIconButton extends StatelessWidget {
  const NslIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  /// สถานะเลือก/เปิดอยู่ (เช่น ปุ่มสลับแผง) — พื้น `selected` และไอคอนสี accent
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final enabled = onPressed != null;
    final side = t.controlHeight(touch: context.nslTouch);
    final fg = !enabled ? c.textFaint : (selected ? t.legibleOn(c.accentInk, c.selected) : c.icon);
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true, // ชื่อสำหรับโปรแกรมอ่านหน้าจอมาจาก NslPressable แล้ว (ไม่ซ้อนสองชั้น)
      child: NslPressable(
        onTap: onPressed,
        radius: t.shape.sm,
        background: selected && enabled ? c.selected : Colors.transparent,
        overlay: fg.withValues(alpha: 0.12),
        ring: c.accent,
        semanticLabel: tooltip,
        selected: selected,
        minHeight: side,
        minWidth: side,
        child: Icon(icon, size: t.type.fit(18), color: fg),
      ),
    );
  }
}
