import 'package:flutter/material.dart';

import '../tokens/nsl_tokens.dart';
import '../tokens/style_tokens.dart';
import 'adjust.dart';

/// ขนาดและสไตล์กลางที่ component ของ nsl_ui ใช้ร่วมกัน — ทุกค่าอ่านจาก token ไม่มีตัวเลขสีหรือมุมโค้งฮาร์ดโค้ด
extension NslComponentMetrics on NslTokens {
  /// ความสูงของตัวควบคุม (ปุ่ม/ช่องกรอก) ตามความหนาแน่น
  /// [touch] = true (จอสัมผัส) : ไม่ต่ำกว่า [kMinTapTarget]
  double controlHeight({bool touch = false}) {
    final h = switch (density) {
      NslDensity.compact => 30.0,
      NslDensity.normal => 38.0,
      NslDensity.comfortable => 46.0,
    };
    return touch && h < kMinTapTarget ? kMinTapTarget : h;
  }

  /// ระยะห่างฐานตามความหนาแน่น (ใช้คูณเป็นขั้น 0.5/1/1.5/2)
  double get gap => switch (density) {
        NslDensity.compact => 6.0,
        NslDensity.normal => 8.0,
        NslDensity.comfortable => 10.0,
      };

  /// สไตล์ตัวอักษร UI : ฟอนต์/ฟอนต์สำรอง/ขนาด (คูณ scale และไม่ต่ำกว่า minSize) จากธีม
  TextStyle textStyle(double size, {FontWeight weight = FontWeight.w400, Color? color, double? height}) => TextStyle(
        fontFamily: type.effectiveFamily,
        fontFamilyFallback: type.fallback,
        fontSize: type.fit(size),
        fontWeight: weight,
        color: color,
        height: height,
      );
}
