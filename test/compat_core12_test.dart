// ความเข้ากันได้ของไฟล์ .nslt ข้ามรุ่น core (1.1 → 1.2 และรุ่นใหม่กว่า)
import 'dart:ui' show Brightness;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

// ไฟล์สไตล์ core 1.1 (ไม่มีคีย์ *Thai) เขียนมือเป็นข้อความตายตัว — ห้ามสร้างจาก serializeNslt เพื่อไม่ให้เทสต์หมุนตามโค้ดใหม่
const _legacy11 = '''
{"schema":1,"core":"1.1","id":"legacy","name":"Legacy","extends":"nsl.nebular",
 "type":{"family":"Inter","content":"Georgia","mono":"Consolas","scale":1.1,"minSize":10},
 "light":{"colors":{"accent":"#2266EE"}}}
''';

void main() {
  test('ไฟล์ core 1.1 เปิดได้ ไม่มีคำเตือน ฟอนต์ไทยว่าง และการเรียงฟอนต์เท่าเดิม', () {
    final r = parseNslt(_legacy11);
    expect(r.ok, isTrue, reason: '${r.errors}');
    expect(r.warnings, isEmpty);
    final s = r.spec!;
    expect((s.familyThai, s.contentThai, s.monoThai), (null, null, null));
    final t = resolveTokens(s, Brightness.light, lookup: builtinThemeById).type;
    expect(t.effectiveFamily, 'Inter');
    expect(t.fallback.first, isNot('Inter'));
    expect(t.fallback.last, kNslFontFallback.last); // ปิดท้ายด้วย Noto เสมอ
    expect(t.thaiFirst, isEmpty);
  });

  test('เขียนไฟล์ 1.1 กลับไม่เติมคีย์ไทยและไม่เปลี่ยนค่าเดิม (อ่าน-เขียน-อ่านได้ผลเท่ากัน)', () {
    final s = parseNslt(_legacy11).spec!;
    final text = serializeNslt(s);
    expect(text, isNot(contains('Thai')));
    final again = parseNslt(text).spec!;
    final a = resolveTokens(s, Brightness.light, lookup: builtinThemeById), b = resolveTokens(again, Brightness.light, lookup: builtinThemeById);
    expect((b.type.family, b.type.content, b.type.mono, b.type.scale, b.type.minSize), (a.type.family, a.type.content, a.type.mono, a.type.scale, a.type.minSize));
  });

  test('ธีมในตัวทุกตัวเขียนออกมาไม่มีคีย์ไทย (ไฟล์ที่แอปเขียนยังอ่านได้ด้วย core เก่า)', () {
    for (final id in ['nsl.nebular', 'nsl.spectrum', 'nsl.orbit']) {
      final spec = builtinThemeById(id);
      if (spec == null) continue;
      expect(serializeNslt(spec), isNot(contains('Thai')), reason: id);
    }
  });

  test('ไฟล์จาก core ใหม่กว่า: คีย์ไทยใช้ได้ คีย์ระดับบนที่ไม่รู้จักไม่หาย มีคำเตือน และคง core เดิมไว้', () {
    final r = parseNslt('{"schema":1,"core":"9.9","id":"f","name":"F","extends":"nsl.nebular","type":{"familyThai":"Sarabun"},"futureTop":7}');
    expect(r.ok, isTrue, reason: '${r.errors}');
    expect(r.warnings.any((w) => w.contains('newer core')), isTrue);
    final out = serializeNslt(r.spec!);
    expect(out, contains('Sarabun'));
    expect(out, contains('futureTop'));
    expect(out, contains('"core": "9.9"'));
  });

  // ช่องโหว่ที่พบ 2026-11-18 (มีมาก่อนเฟส 27) : คีย์ที่ไม่รู้จัก "ภายใน type" ถูกทิ้งตอนเขียนกลับ ต่างจากระดับบนสุด/colors/extensions ที่เก็บไว้
  // ผลจริง: แอปที่ build ด้วย core 1.1 เปิดธีมที่มี familyThai แล้วบันทึกทับ → ฟอนต์ไทยหาย (แอปที่ใช้ core ผ่าน path เดียวกันไม่โดน)
  test('คีย์ที่ไม่รู้จักภายใน type ควรถูกเก็บกลับ', () {
    final r = parseNslt('{"schema":1,"core":"9.9","id":"f","name":"F","extends":"nsl.nebular","type":{"familyThai":"Sarabun","futureKey":{"a":[1,2]}}}');
    expect(serializeNslt(r.spec!), contains('futureKey'));
  });
}
