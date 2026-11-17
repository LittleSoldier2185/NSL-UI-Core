// คีย์ระดับบน `apps` ของไฟล์ .nslt : คำใบ้ว่าธีมออกแบบมาให้แอปไหน (จัดหมวด/กรอง — ไม่จำกัดการใช้งาน)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

String _theme(String extra) =>
    '{"schema":1,"id":"t","name":"T","extends":"nsl.default"$extra}';

void main() {
  test('อ่าน apps : รายชื่อ id ไม่ซ้ำ เรียงตามที่เขียน', () {
    final r = parseNslt(_theme(',"apps":["orbit","lyra","orbit"]'));
    expect(r.spec!.apps, ['orbit', 'lyra']);
    expect(r.warnings, isEmpty);
  });

  test('ไม่มี apps = ว่าง = เหมาะกับทุกแอป', () {
    final s = parseNslt(_theme('')).spec!;
    expect(s.apps, isEmpty);
    expect(s.targets('orbit'), isTrue);
    expect(s.targets('anything'), isTrue);
  });

  test('targets : ระบุแอปแล้วตรงเฉพาะแอปนั้น ; id ที่ไม่รู้จักเก็บไว้', () {
    final s = parseNslt(_theme(',"apps":["orbit","futureapp"]')).spec!;
    expect(s.targets('orbit'), isTrue);
    expect(s.targets('futureapp'), isTrue);
    expect(s.targets('lyra'), isFalse);
  });

  test('เขียนกลับครบ และอ่านซ้ำได้ค่าเดิม (round-trip)', () {
    final s = parseNslt(_theme(',"apps":["orbit","lyra"]')).spec!;
    final out = serializeNslt(s);
    expect((jsonDecode(out) as Map)['apps'], ['orbit', 'lyra']);
    expect(parseNslt(out).spec!.apps, ['orbit', 'lyra']);
  });

  test('ว่าง = ไม่เขียนคีย์', () {
    expect((jsonDecode(serializeNslt(parseNslt(_theme('')).spec!)) as Map).containsKey('apps'), isFalse);
  });

  for (final bad in ['"orbit"', '[1,2]', '["Bad Id"]', '{"a":1}', '[${List.generate(17, (i) => '"a$i"').join(',')}]']) {
    test('apps ผิดรูปแบบ ($bad) : เตือน ไม่ล้ม และเก็บค่าดิบกลับไปตอนบันทึก', () {
      final r = parseNslt(_theme(',"apps":$bad'));
      expect(r.spec, isNotNull);
      expect(r.spec!.apps, isEmpty);
      expect(r.warnings.any((w) => w.contains('apps')), isTrue);
      expect(jsonEncode((jsonDecode(serializeNslt(r.spec!)) as Map)['apps']), jsonEncode(jsonDecode(bad)));
    });
  }

  test('ไม่สืบทอดจากธีมฐาน (ธีมลูกของ nsl.orbit ไม่ระบุ apps = ว่าง)', () {
    final child = parseNslt('{"schema":1,"id":"c","name":"C","extends":"nsl.orbit"}').spec!;
    expect(child.apps, isEmpty);
    expect(resolveTokens(child, Brightness.light, lookup: builtinThemeById).colors.accent, kBuiltinOrbit.light.colors['accent']);
  });

  test('คัดลอก/ติดค่า lite แล้ว apps ยังอยู่', () {
    final s = parseNslt(_theme(',"apps":["orbit"]')).spec!;
    expect(s.copyIdentity(id: 'u', name: 'U').apps, ['orbit']);
    expect(s.withAppearance(null).apps, ['orbit']);
  });

  test('ธีมในตัวระบุแอปของตัวเอง ; nsl.default ว่าง', () {
    expect(builtinThemeById('nsl.orbit')!.apps, ['orbit']);
    expect(builtinThemeById('nsl.nebular')!.apps, ['nebular']);
    expect(builtinThemeById('nsl.spectrum')!.apps, ['spectrum']);
    expect(builtinThemeById('nsl.lyra.paper')!.apps, ['lyra']);
    expect(builtinThemeById('nsl.default')!.apps, isEmpty);
  });

  test('ตัวอ่านรุ่นเก่า (ไม่รู้จัก apps) ก็เก็บไว้ได้ : apps ไม่ใช่คีย์ที่ทำให้ไฟล์พัง', () {
    // จำลองด้วยการอ่านแล้วตรวจว่าไม่มี error — ความเข้ากันได้ย้อนหลังมาจากกติกา "ข้ามคีย์ที่ไม่รู้จัก"
    final r = parseNslt(_theme(',"apps":["orbit"],"zzz":1'));
    expect(r.errors, isEmpty);
    expect(r.spec!.unknown['zzz'], 1);
  });

  test('NslThemeDraft เก็บ apps ผ่านไป-กลับ', () {
    final d = NslThemeDraft.fromSpec(parseNslt(_theme(',"apps":["orbit","lyra"]')).spec!);
    expect(d.apps, ['orbit', 'lyra']);
    expect(d.toSpec().apps, ['orbit', 'lyra']);
  });
}
