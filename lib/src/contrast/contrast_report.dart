import 'dart:ui';

import '../tokens/nsl_tokens.dart';
import 'contrast.dart';

/// หนึ่งการตรวจ contrast ระหว่างสีตัวอักษร/ไอคอนกับพื้น
class ContrastCheck {
  const ContrastCheck(this.name, this.fg, this.bg, this.ratio, this.min);

  /// เช่น `text/surface`
  final String name;
  final String fg, bg;
  final double ratio;
  final double min;

  bool get passes => ratio >= min;
}

/// ตรวจ contrast ของ token ตามกติกาในแผน (ข้อ 9)
///
/// - ตัวอักษร/พื้น >= 4.5 : `text/surface`, `text/bg`, `textMuted/surface`, `accentInk/surface`, `onAccent/accent`, `*Text/*Bg`
/// - เส้นขอบเห็นได้ >= 1.3 : `border/surface`
List<ContrastCheck> checkContrast(NslTokens t) {
  final c = t.colors;
  final backdrop = _flatten(c.surface, c.bg);
  ContrastCheck chk(String fg, String bg, double min) {
    // สีโปร่งใส (#RRGGBBAA) วัดตามที่ตาเห็นจริง : พื้นโปร่งผสมบนพื้นด้านหลัง แล้วตัวอักษรโปร่งผสมบนพื้นนั้น
    final b = bg == 'surface' ? backdrop : _flatten(c[bg], backdrop);
    final f = _flatten(c[fg], b);
    return ContrastCheck('$fg/$bg', fg, bg, contrastRatio(f, b), min);
  }
  return [
    chk('text', 'surface', 4.5),
    chk('text', 'bg', 4.5),
    chk('textMuted', 'surface', 4.5),
    chk('accentInk', 'surface', 4.5),
    chk('onAccent', 'accent', 4.5),
    chk('dangerText', 'dangerBg', 4.5),
    chk('warnText', 'warnBg', 4.5),
    chk('infoText', 'infoBg', 4.5),
    chk('successText', 'successBg', 4.5),
    chk('border', 'surface', 1.3),
  ];
}

/// เฉพาะรายการที่ไม่ผ่าน
List<ContrastCheck> contrastFailures(NslTokens t) => [for (final k in checkContrast(t)) if (!k.passes) k];

/// ธีมที่ใช้ไม่ได้จริง (ตัวอักษรหลักเทียบพื้นต่ำกว่า 3:1) — แอปควรถอยไปใช้ธีมในตัว (safe mode)
bool isUnusable(NslTokens t) {
  final c = t.colors;
  final surface = _flatten(c.surface, c.bg), bg = _flatten(c.bg, surface);
  return contrastRatio(_flatten(c.text, bg), bg) < 3 || contrastRatio(_flatten(c.text, surface), surface) < 3;
}

/// ผสมสีโปร่งใส [x] บนพื้นด้านหลัง [back] (ถ้าด้านหลังก็โปร่งใส ใช้ดำเป็นฐาน) ; สีทึบคืนค่าเดิม
Color _flatten(Color x, Color back) => x.a >= 1 ? x : Color.alphaBlend(x, back.a >= 1 ? back : const Color(0xFF000000));
