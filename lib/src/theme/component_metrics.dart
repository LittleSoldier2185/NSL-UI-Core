import 'package:flutter/material.dart';

import '../contrast/contrast.dart';
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

  /// สีตัวอักษร/ไอคอน [fg] ที่รับประกันอ่านได้บนพื้น [bg] (contrast >= [min])
  ///
  /// ผ่านอยู่แล้วคืน [fg] เดิม (ไม่เปลี่ยนสิ่งที่ผู้ออกแบบธีมตั้งใจ) ; ไม่ผ่านจึงขยับเข้าหาดำ/ขาว
  /// ตามความสว่างของพื้น — core รับประกันเฉพาะบางคู่สี (เช่น `onAccent/accent` ที่ธีมในตัวบางโหมดยังไม่ผ่าน
  /// และ `accentInk/accentTint` ที่ไม่ได้ตรวจ) component จึงกันไว้เองตรงจุดที่ใช้
  /// พื้นโปร่งใสถูกผสมบน `surface` ก่อนวัด
  Color legibleOn(Color fg, Color bg, {double min = 4.5}) {
    final back = Color.alphaBlend(bg, colors.surface);
    if (contrastRatio(fg, back) >= min) return fg;
    // ความสว่างที่ดำและขาวให้ contrast เท่ากัน ≈ 0.179 : พื้นสว่างกว่านี้ใช้ตัวอักษรเข้ม
    return ensureContrast(fg, back, min, light: back.computeLuminance() > 0.179);
  }

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
