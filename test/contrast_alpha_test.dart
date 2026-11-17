// contrast ของสีโปร่งใส (#RRGGBBAA) ต้องวัดตามที่ตาเห็นจริง (ผสมบนพื้น) ไม่ใช่เอาค่า RGB ดิบมาเทียบ
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

NslTokens _t(String colors, {Brightness b = Brightness.dark}) {
  final spec = parseNslt('{"schema":1,"id":"t","name":"t","dark":{"colors":$colors},"light":{"colors":$colors}}').spec!;
  return resolveTokens(spec, b);
}

const _base = '"bg":"#071433","surface":"#0E1D45","text":"#FFFFFF","accent":"#FFC83D"';

void main() {
  ContrastCheck find(NslTokens t, String name) => checkContrast(t).firstWhere((c) => c.name == name);

  test('พื้นป้ายโปร่งใส: วัดบนพื้นที่ผสมแล้ว ไม่ใช่สี RGB ดิบ (เดิมได้ ~1.2:1 ทั้งที่จริงอ่านชัด)', () {
    final t = _t('{$_base,"successBg":"#4FE3B024","successText":"#7DF0C6"}');
    final blended = Color.alphaBlend(const Color(0x244FE3B0), const Color(0xFF0E1D45));
    final want = contrastRatio(const Color(0xFF7DF0C6), blended);
    final got = find(t, 'successText/successBg');
    expect(got.ratio, closeTo(want, 1e-9));
    expect(got.ratio, greaterThan(4.5));
    expect(got.passes, isTrue);
    // ค่าดิบ (ผิด) จะได้ต่ำมาก — พิสูจน์ว่าแก้จริง
    expect(contrastRatio(const Color(0xFF7DF0C6), const Color(0xFF4FE3B0)), lessThan(1.5));
  });

  test('เส้นขอบโปร่งใส: ขาว 12% (ดีไซน์ Launcher) ผ่านเกณฑ์ 1.3 จริง (~1.43) ; ขาว 6% จางเกินไปถูกรายงานว่าไม่ผ่าน', () {
    final surface = const Color(0xFF0E1D45);
    for (final (hex, alpha, passes) in [('1F', 0x1F, true), ('0F', 0x0F, false)]) {
      final t = _t('{$_base,"border":"#FFFFFF$hex"}');
      final c = find(t, 'border/surface');
      final blended = Color.alphaBlend(Color.fromARGB(alpha, 255, 255, 255), surface);
      expect(c.ratio, closeTo(contrastRatio(blended, surface), 1e-9), reason: hex);
      expect(c.passes, passes, reason: '$hex ratio=${c.ratio}');
    }
    // ค่าดิบ (ขาวทึบเทียบพื้น) ได้สูงมากเสมอ จึง "ผ่าน" ทุกกรณีทั้งที่ตาแทบมองไม่เห็นขอบ 6% — นี่คือสิ่งที่แก้
    expect(contrastRatio(const Color(0xFFFFFFFF), surface), greaterThan(10));
  });

  test('ตัวอักษรโปร่งใส (muted ขาว 50%) ผสมบนพื้นก่อนวัด', () {
    final t = _t('{$_base,"textMuted":"#FFFFFF80"}');
    final c = find(t, 'textMuted/surface');
    final f = Color.alphaBlend(const Color(0x80FFFFFF), const Color(0xFF0E1D45));
    expect(c.ratio, closeTo(contrastRatio(f, const Color(0xFF0E1D45)), 1e-9));
  });

  test('สีทึบไม่เปลี่ยนพฤติกรรม (ธีมในตัวทั้งหมดผลเท่าเดิม — parity เทสต์ชุดเดิมคุมอยู่)', () {
    final t = _t('{$_base}');
    for (final c in checkContrast(t)) {
      final fg = t.colors[c.fg], bg = t.colors[c.bg];
      expect(c.ratio, closeTo(contrastRatio(fg, bg), 1e-9), reason: c.name);
    }
  });

  test('isUnusable: ตัวอักษรโปร่งใสมากจนมองไม่เห็นถูกจับได้ แต่ขาวโปร่ง 80% บนพื้นเข้มยังใช้ได้', () {
    expect(isUnusable(_t('{$_base,"text":"#FFFFFF14"}')), isTrue);
    expect(isUnusable(_t('{$_base,"text":"#FFFFFFCC"}')), isFalse);
  });
}
