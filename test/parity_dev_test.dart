// Parity: ธีมในตัว `nsl.nebular` ต้องให้ค่าเท่าพาเลตต์จริงของ NSL Dev ทุกช่อง
//
// อิมพอร์ต theme.dart ของแอปตรง ๆ แบบอ่านอย่างเดียว (ไม่แก้ไฟล์ของแอป ไม่คัดลอกค่ามาไว้ในเทสต์)
// ดังนั้นถ้า NSL Dev เปลี่ยนสีในอนาคต เทสต์นี้จะล้มและบอกว่าธีมในตัวต้องอัปเดต

// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

import '../../NSL-Nebular/lib/ui/theme.dart' as dev;

void main() {
  tearDown(() => dev.C.use(dev.kLightPalette));

  for (final entry in {Brightness.light: dev.kLightPalette, Brightness.dark: dev.kDarkPalette}.entries) {
    final b = entry.key;
    final p = entry.value;

    test('nsl.nebular ($b) เท่า Palette และ C ของ NSL Dev ทุกช่องที่แอปมี', () {
      dev.C.use(p);
      final t = resolveTokens(kBuiltinDev, b);
      final c = t.colors;

      final expected = <String, Color>{
        'bg': p.bg,
        'chrome': p.bg,
        'surface': p.surface,
        'surfaceRaised': p.surfaceHi,
        'surfaceSunken': p.field,
        'borderSoft': p.borderSoft,
        'border': p.border,
        'borderStrong': p.inputBorder,
        'text': p.text,
        'textMuted': p.muted,
        'accent': p.primary,
        'accentInk': p.primaryDark,
        'accentTint': p.primaryTint,
        'onAccent': Colors.white,
        'danger': dev.C.danger,
        'dangerBg': dev.C.dangerBg,
        'dangerText': dev.C.dangerText,
        'warnBg': p.warnBg,
        'warnText': p.warnText,
        'infoBg': p.infoBg,
        'infoText': p.infoText,
        'shadow': p.shadow,
      };
      for (final e in expected.entries) {
        expect(c[e.key], e.value, reason: 'core.${e.key}');
      }

      final ext = <String, Color>{
        'canvas': p.canvas,
        'dot': p.dot,
        'tableHead': p.tableHead,
        'pkBg': p.pkBg,
        'pkText': p.pkText,
        'uqBg': p.uqBg,
        'uqText': p.uqText,
        'nnBg': p.nnBg,
        'nnText': p.nnText,
        'boardOutside': dev.C.boardOutside,
        'boardEdge': dev.C.boardEdge,
        'fkSource': dev.C.fkSource,
        'fkChip': dev.C.fkChip,
      };
      for (final e in ext.entries) {
        expect(t.ext('nebular', e.key), e.value, reason: 'dev.${e.key}');
      }
    });
  }

  test('ธีม nsl.default มีค่าเท่า nsl.nebular (ตอนนี้) แต่เป็นคนละ id', () {
    for (final b in Brightness.values) {
      expect(resolveTokens(kBuiltinDefault, b), resolveTokens(kBuiltinDev, b));
    }
    expect(kBuiltinDefault.id, isNot(kBuiltinDev.id));
  });

  test('ธีมในตัวของ Dev ผ่านเกณฑ์ contrast ที่ตั้งไว้ (ยกเว้นที่แอปเดิมไม่ผ่านอยู่แล้ว จะรายงานไว้)', () {
    for (final b in Brightness.values) {
      final t = resolveTokens(kBuiltinDev, b);
      expect(isUnusable(t), isFalse);
      // ข้อมูลประกอบ: รายการที่ไม่ผ่านของธีมเดิม (ไม่ล้มเทสต์ — ธีมในตัวต้องเหมือนเดิมแม้ไม่ผ่านเกณฑ์ใหม่)
      final fails = contrastFailures(t).map((e) => '${e.name}=${e.ratio.toStringAsFixed(2)}').toList();
      // ignore: avoid_print
      print('nsl.nebular $b contrast ที่ไม่ผ่านเกณฑ์: ${fails.isEmpty ? "-" : fails.join(", ")}');
    }
  });
}
