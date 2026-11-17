// ธีมในตัว nsl.orbit : ค่าตรงกับพาเลตต์ global ใน NSL-Orbit/lib/ui.dart (อ่านมือ — ui.dart import share_plus จึง import ตรง ๆ
// จากเทสต์ของ core ไม่ได้ ; เทียบกับ global จริงอยู่ในเทสต์ของสำเนา experiments/orbit_copy)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

void main() {
  test('ลงทะเบียนเป็นธีมในตัว และ resolve ได้ทั้งสองโหมดโดยไม่มีคำเตือน', () {
    expect(kBuiltinThemeIds, contains('nsl.orbit'));
    expect(builtinThemeById('nsl.orbit'), same(kBuiltinOrbit));
    for (final b in Brightness.values) {
      expect(() => resolveTokens(kBuiltinOrbit, b), returnsNormally);
    }
  });

  test('ค่าหลักตรงกับพาเลตต์ Orbit (สว่าง / มืด)', () {
    final l = resolveTokens(kBuiltinOrbit, Brightness.light).colors, d = resolveTokens(kBuiltinOrbit, Brightness.dark).colors;
    expect([l.bg, l.surface, l.border, l.borderSoft, l.text, l.textMuted, l.accent, l.accentInk, l.accentTint],
        [0xFFF2F4F6, 0xFFFFFFFF, 0xFFE3E8EC, 0xFFEEF1F4, 0xFF14202B, 0xFF5F6E7B, 0xFF0B6E7A, 0xFF08525B, 0xFFD8EEF0].map(Color.new));
    expect([d.bg, d.surface, d.surfaceRaised, d.border, d.borderSoft, d.text, d.textMuted, d.accent, d.accentInk, d.accentTint],
        [0xFF0B0F13, 0xFF151C22, 0xFF2B3843, 0xFF26313A, 0xFF1E272F, 0xFFE8EDF1, 0xFFA2B0BC, 0xFF1B8C9A, 0xFF8ADAE3, 0xFF1C3F45].map(Color.new));
  });

  test('มุมโค้ง : ปุ่ม/ช่องกรอก 12, dialog 20, แผ่นล่าง 24', () {
    final s = resolveTokens(kBuiltinOrbit, Brightness.light).shape;
    expect([s.md, s.lg, s.xl], [12, 20, 24]);
  });

  for (final b in Brightness.values) {
    test('contrast ของคู่สีหลัก ≥ 4.5 (${b.name})', () {
      final c = resolveTokens(kBuiltinOrbit, b).colors;
      for (final (name, fg, bg) in [
        ('text/bg', c.text, c.bg),
        ('text/surface', c.text, c.surface),
        ('textMuted/surface', c.textMuted, c.surface),
        ('accentInk/accentTint', c.accentInk, c.accentTint),
        ('accentInk/surface', c.accentInk, c.surface),
      ]) {
        expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5), reason: name);
      }
    });
  }

  test('buildNslThemeData : snackbar โหมดมืดใช้ segSel ของ Orbit, dialog มุม 20', () {
    final dark = buildNslThemeData(resolveTokens(kBuiltinOrbit, Brightness.dark));
    expect(dark.snackBarTheme.backgroundColor, const Color(0xFF2B3843));
    expect(dark.snackBarTheme.contentTextStyle!.color, const Color(0xFFE8EDF1));
    final light = buildNslThemeData(resolveTokens(kBuiltinOrbit, Brightness.light));
    expect((light.dialogTheme.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(20));
    expect(light.colorScheme.primary, const Color(0xFF0B6E7A));
  });

  test('accent ของ lite ทับธีมนี้ได้ (accent ชุดอื่นของ Orbit)', () {
    final t = resolveTokens(kBuiltinOrbit.withAppearance(const NslAppearance(mode: NslModeChoice.light, customAccent: Color(0xFF6842C0))), Brightness.light);
    // accent ถูกขยับให้ตัวอักษรขาวบนปุ่มอ่านออก (เหมือน accentTints ของ Orbit) — ไม่เท่าค่าที่ส่งเข้าไปเสมอ
    expect(t.colors.accent, isNot(kBuiltinOrbit.light.colors['accent']));
    expect(contrastRatio(t.colors.onAccent, t.colors.accent), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(t.colors.accentInk, t.colors.accentTint), greaterThanOrEqualTo(4.5));
  });
}
