import 'package:flutter/material.dart';

import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';

/// สีของแถบที่เติม
enum NslProgressTone { accent, success, danger }

/// แถบความคืบหน้าแบบทราบค่า (0–1) — ไม่มีโหมดไม่ทราบค่า/แอนิเมชัน (ใช้ `LinearProgressIndicator` ของ Material ถ้าต้องการ)
///
/// [label] จำเป็น : บอกโปรแกรมอ่านหน้าจอว่าแถบนี้คืออะไร (ค่าเปอร์เซ็นต์ใส่ให้เอง)
/// ความกว้างเต็มพื้นที่ที่พ่อให้ — ห้ามวางในพื้นที่ที่ความกว้างไม่จำกัด (เช่น Row ตรง ๆ ให้ครอบด้วย Expanded/SizedBox)
class NslProgressBar extends StatelessWidget {
  const NslProgressBar({super.key, required this.value, required this.label, this.tone = NslProgressTone.accent});

  /// ค่านอกช่วงถูกตัดเป็น 0–1 ; NaN = 0
  final double value;
  final String label;
  final NslProgressTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final fill = switch (tone) {
      NslProgressTone.accent => c.accent,
      NslProgressTone.success => c.success,
      NslProgressTone.danger => c.danger,
    };
    return Semantics(
      label: label,
      value: '${(v * 100).round()}%',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(t.shape.pill),
          child: SizedBox(
            height: t.gap,
            // ราง = border (core รับประกัน border/surface ≥ 1.3 จึงเห็นรางเสมอ)
            child: ColoredBox(
              color: c.border,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: v, heightFactor: 1, child: ColoredBox(color: fill)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
