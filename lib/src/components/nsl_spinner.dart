import 'package:flutter/material.dart';

import '../theme/nsl_theme.dart';

/// ขนาดวงหมุน
enum NslSpinnerSize { sm, md, lg }

/// วงหมุนแสดงว่ากำลังโหลด (ไม่ทราบความคืบหน้า) — สี accentInk (ผ่าน contrast บนพื้นผิวทุกธีม — accent บางธีมจางเกินไป) ราง border
///
/// [label] จำเป็น : บอกโปรแกรมอ่านหน้าจอว่ากำลังโหลดอะไร (เช่น "กำลังโหลดรายการ")
/// หมายเหตุ : หมุนตลอดเวลา — เทสต์ที่ใช้ `pumpAndSettle` ไม่ควรวางไว้ในหน้าที่ทดสอบ
class NslSpinner extends StatelessWidget {
  const NslSpinner({super.key, required this.label, this.size = NslSpinnerSize.md});

  final String label;
  final NslSpinnerSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final (px, stroke) = switch (size) {
      NslSpinnerSize.sm => (16.0, 2.0),
      NslSpinnerSize.md => (24.0, 3.0),
      NslSpinnerSize.lg => (40.0, 4.0),
    };
    final d = t.type.fit(px);
    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: SizedBox(
        width: d,
        height: d,
        child: CircularProgressIndicator(strokeWidth: stroke, color: c.accentInk, backgroundColor: c.border),
      ),
    );
  }
}
