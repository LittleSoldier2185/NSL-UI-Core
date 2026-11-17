import 'package:flutter/material.dart';

import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';

/// สถานะว่าง : "ยังไม่มีข้อมูล", "ไม่ได้เลือกรายการ", "ไม่พบผลลัพธ์" — ไอคอน + หัวข้อ + คำอธิบาย + ปุ่ม (ถ้ามี)
///
/// จัดกึ่งกลางในพื้นที่ที่ได้ และจำกัดความกว้างข้อความไม่ให้ยาวจนอ่านยาก
/// [action] เป็น widget อะไรก็ได้ (ปกติ `NslButton`) ; ไอคอนเป็นของตกแต่ง ไม่ถูกอ่านโดยโปรแกรมอ่านหน้าจอ
class NslEmptyState extends StatelessWidget {
  const NslEmptyState({super.key, required this.title, this.message, this.icon, this.action});

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: EdgeInsets.all(t.gap * 3),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            ExcludeSemantics(child: Icon(icon, size: t.type.fit(36), color: c.icon)),
            SizedBox(height: t.gap * 1.5),
          ],
          Text(title, textAlign: TextAlign.center, style: t.textStyle(16, weight: FontWeight.w600, color: c.text)),
          if (message != null) ...[
            SizedBox(height: t.gap / 2),
            Text(message!, textAlign: TextAlign.center, style: t.textStyle(13, color: c.textMuted, height: 1.4)),
          ],
          if (action != null) ...[SizedBox(height: t.gap * 2), action!],
        ]),
      ),
    );
    // พื้นที่พอ = กึ่งกลาง ; พื้นที่เล็กเกินเนื้อหา (แผงแคบ + ตัวอักษรใหญ่) = เลื่อนได้ ไม่ล้น
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.hasBoundedHeight ? box.maxHeight : 0),
          child: Center(child: content),
        ),
      ),
    );
  }
}
