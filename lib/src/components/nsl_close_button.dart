import 'package:flutter/material.dart';

import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';
import 'pressable.dart';

/// ปุ่มปิด (กากบาท) สำหรับ alert/แผง/แถบ — ขนาดตาม density และไม่เล็กกว่า 44 บนจอสัมผัส
///
/// [tooltip] จำเป็น (เช่น "ปิด") : เป็นทั้ง tooltip และชื่อสำหรับโปรแกรมอ่านหน้าจอ
/// [color] ไม่ระบุ = สีไอคอนของธีม ; วางบนพื้นสีอื่น (เช่นใน [NslAlert]) ให้ส่งสีที่ผ่าน contrast บนพื้นนั้นเข้ามา
class NslCloseButton extends StatelessWidget {
  const NslCloseButton({super.key, required this.onPressed, required this.tooltip, this.color});

  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final enabled = onPressed != null;
    final fg = !enabled ? c.textFaint : (color ?? c.icon);
    final side = t.controlHeight(touch: context.nslTouch);
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: NslPressable(
        onTap: onPressed,
        radius: t.shape.sm,
        background: Colors.transparent,
        overlay: fg.withValues(alpha: 0.12),
        ring: c.accent,
        semanticLabel: tooltip,
        minHeight: side,
        minWidth: side,
        child: Icon(Icons.close, size: t.type.fit(18), color: fg),
      ),
    );
  }
}
