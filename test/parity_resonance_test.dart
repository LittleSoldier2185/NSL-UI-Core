// Parity: ธีมในตัว `nsl.spectrum` ต้องให้ค่าเท่า `NslPalette.of(...)` จริงของ NSL Resonance ทุกช่อง
//
// อิมพอร์ต theme.dart ของแอปตรง ๆ แบบอ่านอย่างเดียว (ไม่แก้ไฟล์ของแอป)

// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

import '../../NSL-Media-Player/lib/ui/theme.dart' as res;

void main() {
  final accents = <Color>[res.defaultAccent, ...res.accentPresets.map((e) => e.$2), const Color(0xFF0B1F3A), const Color(0xFFFFFFFF), const Color(0xFF000000)];

  for (final b in Brightness.values) {
    for (final accent in accents) {
      test('nsl.spectrum ($b, accent ${accent.toARGB32().toRadixString(16)}) เท่า NslPalette.of ทุกช่อง', () {
        final pal = res.NslPalette.of(b, accent);
        final t = resolveTokens(builtinResonance(accent), b);
        final c = t.colors;

        final expected = <String, Color>{
          'bg': pal.bg,
          'chrome': pal.titleBar,
          'surface': pal.panelTop,
          'surfaceRaised': pal.panelTop,
          'surfaceSunken': pal.track,
          'borderSoft': pal.panelBorder,
          'borderStrong': pal.border,
          'text': pal.text,
          'textMuted': pal.textDim,
          'icon': pal.icon,
          'hover': pal.hover,
          'accent': pal.accent,
          'accentInk': pal.accentInk,
          'onAccent': pal.onAccent,
        };
        for (final e in expected.entries) {
          expect(c[e.key], e.value, reason: 'core.${e.key}');
        }
        expect(t.ext('spectrum', 'panelBottom'), pal.panelBottom);
      });
    }
  }

  test('ฟังก์ชัน contrast/inkFor/onAccentFor ที่ย้ายมา ให้ผลเท่าของเดิมใน Resonance', () {
    const colors = [
      Color(0xFFF4B860), Color(0xFF7DD3C0), Color(0xFF8AB4F8), Color(0xFFF08A8A),
      Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFF336699), Color(0xFF0F766E), Color(0xFF808080),
    ];
    const surfaces = [Color(0xFFFFFFFF), Color(0xFF14151A), Color(0xFF18191F)];
    for (final a in colors) {
      expect(onAccentFor(a), res.onAccentFor(a));
      for (final s in surfaces) {
        expect(contrastRatio(a, s), res.contrast(a, s));
        expect(inkFor(a, s, true), res.inkFor(a, s, true));
        expect(inkFor(a, s, false), res.inkFor(a, s, false));
      }
    }
  });

  test('ตัวคำนวณ accentInk ของ Resonance ทำงานกับพื้น 14151A (ไม่ใช่ panelTop) — ธีมในตัวคงพฤติกรรมนี้', () {
    // ถ้าผู้ใช้สืบทอด nsl.spectrum แล้วเปลี่ยน accent โดยไม่ระบุ accentInk ค่าจะถูกคำนวณใหม่กับ surface ของธีม (18191F)
    // ซึ่งอาจต่างจากของเดิมเล็กน้อย — ตรวจว่ายังผ่าน 4.5:1 เสมอ
    for (final accent in [const Color(0xFF0B1F3A), const Color(0xFFD97706), const Color(0xFF1E40AF)]) {
      final child = NslThemeSpec(
        id: 'child',
        name: 'child',
        extendsId: kBuiltinResonanceId,
        light: NslModeSpec(colors: {'accent': accent}),
        dark: NslModeSpec(colors: {'accent': accent}),
      );
      for (final b in Brightness.values) {
        final t = resolveTokens(child, b, lookup: builtinThemeById);
        expect(contrastRatio(t.colors.accentInk, t.colors.surface), greaterThanOrEqualTo(4.5), reason: '$b $accent');
      }
    }
  });
}
