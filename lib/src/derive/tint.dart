import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

import '../contrast/contrast.dart';

/// ชุดสีจาก accent ที่ผู้ใช้เลือกเอง: (accent ที่ปรับให้อ่านได้, พื้นอ่อน, ตัวอักษรบนพื้นอ่อน)
typedef NslAccentSet = (Color accent, Color soft, Color ink);

const _white = Color(0xFFFFFFFF);

/// แปลงสีใด ๆ ที่ผู้ใช้เลือกให้เป็นชุดสี accent ที่ใช้ได้จริง
///
/// พอร์ตจาก NSL Utility (`accentTints`) โดยคงสูตร HSL เดิมทุกตัว เพื่อให้สีที่ผู้ใช้เคยตั้งไม่เปลี่ยน :
/// accent ถูกขยับให้เข้มจนตัวอักษรขาวบนพื้น accent อ่านได้ (>= 4.5 ธีมสว่าง, >= 3.6 ธีมมืด)
/// ส่วนพื้นอ่อนและตัวอักษรบนพื้นอ่อนตามโหมดสว่าง/มืด
NslAccentSet accentTints(Color base, bool dark) {
  final h = HSLColor.fromColor(base), sat = h.saturation.clamp(.3, .95).toDouble();
  var l = (dark ? h.lightness.clamp(.42, .62) : h.lightness.clamp(.25, .45)).toDouble();
  Color make(double light) => HSLColor.fromAHSL(1, h.hue, sat, light).toColor();
  var acc = make(l);
  while (contrastRatio(acc, _white) < (dark ? 3.6 : 4.5) && l > .1) {
    l -= .02;
    acc = make(l);
  }
  final soft = HSLColor.fromAHSL(1, h.hue, dark ? sat * .45 : sat * .6, dark ? .18 : .92).toColor();
  final on0 = HSLColor.fromAHSL(1, h.hue, dark ? sat * .8 : sat, dark ? .78 : .24).toColor();
  // ของเดิมไม่รับประกันตัวอักษรบนพื้นอ่อน : ถ้ายังไม่ถึง 4.5 ค่อยขยับ (ค่าที่ผ่านอยู่แล้วคงเดิมทุกบิต)
  final on = ensureContrast(on0, soft, 4.5, light: !dark);
  return (acc, soft, on);
}

/// คู่ (พื้น, ตัวอักษร) ที่อ่านได้ (>= 4.5) สำหรับสีใด ๆ ตามโหมด — ใช้กับสีที่ผู้ใช้เลือกอิสระ
/// (สีวิชา, สีหมวดหมู่, ป้ายสถานะ ฯลฯ) ; พอร์ตจาก NSL Utility (`subjectTints`) โดยคงสูตรเดิม
(Color bg, Color fg) tintFor(Color base, bool dark) {
  final h = HSLColor.fromColor(base), sat = h.saturation.clamp(.3, .95).toDouble();
  final bg = HSLColor.fromAHSL(1, h.hue, dark ? sat * .5 : sat * .6, dark ? .2 : .92).toColor();
  final fg = HSLColor.fromAHSL(1, h.hue, sat, dark ? .78 : .26).toColor();
  // ของเดิมไม่รับประกัน contrast กับสีบางกลุ่ม (เช่น ฟ้าอมเขียวสด ได้ ~4.2) : ถ้าไม่ถึง 4.5 ค่อยขยับ
  // ค่าที่ผ่านอยู่แล้วคงเดิมทุกบิต (ดู golden test)
  return (bg, ensureContrast(fg, bg, 4.5, light: !dark));
}
