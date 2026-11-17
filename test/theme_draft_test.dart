import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

void main() {
  test('slugify: ชื่อ → id ที่ใช้เป็นชื่อไฟล์ได้เสมอ', () {
    expect(NslThemeDraft.slugify('My Ocean Theme!'), 'my-ocean-theme');
    expect(NslThemeDraft.slugify('ธีมของฉัน'), 'theme');
    expect(NslThemeDraft.slugify('../../evil'), 'evil');
    expect(isValidThemeId(NslThemeDraft.slugify('A' * 200)), isTrue);
    expect(isReservedThemeId(NslThemeDraft.slugify('nsl.nebular')), isTrue); // ผู้เรียกต้องตรวจสงวนเอง
  });

  test('toSpec → serialize → parse ได้ค่าเดิม', () {
    final d = NslThemeDraft(name: 'Ocean', radiusMd: 12, scale: 1.1, density: NslDensity.compact)
      ..light['accent'] = const Color(0xFF1D4ED8);
    final spec = parseNslt(serializeNslt(d.toSpec())).spec!;
    expect(spec.id, 'ocean');
    expect(spec.radius['md'], 12);
    expect(spec.light.colors['accent'], const Color(0xFF1D4ED8));
  });

  test('ธีมที่ contrast ไม่ผ่าน → autoFix แก้ให้ผ่านทั้งสองโหมด และไม่แตะสีพื้น/accent ที่ผู้ใช้เลือก', () {
    final d = NslThemeDraft(name: 'Bad')
      ..light['bg'] = const Color(0xFFFFFFFF)
      ..light['surface'] = const Color(0xFFFFFFFF)
      ..light['text'] = const Color(0xFFCCCCCC) // อ่านยาก
      ..dark['text'] = const Color(0xFF444444);
    expect(d.failures(Brightness.light, builtinThemeById), isNotEmpty);
    final n = d.autoFix(builtinThemeById);
    expect(n, greaterThan(0));
    expect(d.failures(Brightness.light, builtinThemeById), isEmpty);
    expect(d.failures(Brightness.dark, builtinThemeById), isEmpty);
    expect(d.light['bg'], const Color(0xFFFFFFFF));
    expect(d.autoFix(builtinThemeById), 0); // ซ้ำแล้วไม่เปลี่ยนอีก
  });

  test('ธีมฐานหาย → resolve โยน NslResolveException', () {
    final d = NslThemeDraft(name: 'x', baseId: 'ghost');
    expect(() => d.resolve(Brightness.light, builtinThemeById), throwsA(isA<NslResolveException>()));
  });

  test('fromSpec → toSpec ไม่ทำค่าหาย', () {
    final s = parseNslt('{"schema":1,"id":"o","name":"O","extends":"nsl.nebular","density":"compact","shape":{"radius":{"md":10}},"light":{"colors":{"accent":"#112233"}}}').spec!;
    final back = NslThemeDraft.fromSpec(s).toSpec();
    expect(back.id, 'o');
    expect(back.density, NslDensity.compact);
    expect(back.radius['md'], 10);
    expect(back.light.colors['accent'], const Color(0xFF112233));
  });
  test('ธีมมืดในตัวของ Dev (ขาวบน accent 3.68:1) → autoFix ทำให้ผ่านโดยเปลี่ยน onAccent เป็นเข้ม', () {
    final d = NslThemeDraft(name: 'DevDark');
    expect(d.failures(Brightness.dark, builtinThemeById), isNotEmpty);
    d.autoFix(builtinThemeById);
    expect(d.failures(Brightness.dark, builtinThemeById), isEmpty);
    expect(d.dark.containsKey('onAccent'), isTrue);
  });
}
