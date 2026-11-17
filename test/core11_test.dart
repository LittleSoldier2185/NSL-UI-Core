// core 1.1: ส่วนขยาย lyra + ธีมในตัว nsl.lyra.paper + กติกา "คีย์ของส่วนขยายที่ขึ้นกับ accent"
// (parity ของ nsl.lyra.paper กับ theme.dart จริงของ Lyra อยู่ในเทสต์ของสำเนา experiments/lyra_copy เพราะต้องใช้ drift/google_fonts ของแอป)
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

NslTokens _res(NslThemeSpec s, Brightness b, {NslThemeLookup? lookup}) => resolveTokens(s, b, lookup: lookup ?? builtinThemeById);

void main() {
  test('เวอร์ชัน core = 1.1 และ schema บอกว่า lyra เริ่มมีใน 1.1 (nebular/spectrum ใน 1.0)', () {
    expect(kNslCoreVersion, '1.1');
    final ext = {for (final e in (buildTokensSchema()['extensions'] as List).cast<Map<String, Object?>>()) e['name']: e['since']};
    expect(ext, {'nebular': '1.0', 'spectrum': '1.0', 'lyra': '1.1'});
  });

  for (final b in Brightness.values) {
    test('nsl.lyra.paper ($b): ครบทุกคีย์ของ lyra และ resolve ได้ ; ระบุค่าเองทุกตัว (ไม่พึ่ง derive)', () {
      final t = _res(kBuiltinLyraPaper, b);
      for (final k in kLyraExtension.keys) {
        expect(t.ext('lyra', k), isNotNull, reason: k);
        expect(kBuiltinLyraPaper.mode(b).extensions['lyra']!.containsKey(k), isTrue, reason: 'paper ต้องระบุ $k เอง');
      }
      expect(kLyraExtension.keys.length, 22);
      expect(kLyraTypes.length, 7);
      expect(kLyraStatuses.length, 3);
    });

    test('nsl.default ($b): lyra ถูก derive ครบและแยกสีประเภทได้ทั้ง 7 แบบ', () {
      final t = _res(kBuiltinDefault, b);
      final types = [for (final n in kLyraTypes) t.ext('lyra', 'type${n[0].toUpperCase()}${n.substring(1)}')];
      expect(types.every((c) => c != null), isTrue);
      expect(types.toSet().length, 7);
      for (final n in kLyraStatuses) {
        final cap = '${n[0].toUpperCase()}${n.substring(1)}';
        expect(contrastRatio(t.ext('lyra', 'status${cap}Fg')!, t.ext('lyra', 'status${cap}Bg')!), greaterThanOrEqualTo(4.5), reason: n);
      }
    });
  }

  test('ธีมลูกเปลี่ยน accent: คีย์ของส่วนขยายที่ขึ้นกับ accent (lyra.accentDark, nebular.fkChip) ถูกคำนวณใหม่ ; ถ้าระบุเองไว้คงตามนั้น', () {
    const red = Color(0xFFC0392B);
    final paperAccent = _res(kBuiltinLyraPaper, Brightness.light).ext('lyra', 'accentDark');
    final child = const NslThemeSpec(id: 'c', name: 'c', extendsId: kBuiltinLyraPaperId, light: NslModeSpec(colors: {'accent': red}));
    final t = _res(child, Brightness.light);
    expect(t.ext('lyra', 'accentDark'), isNot(paperAccent), reason: 'ต้องไม่ค้างเป็นค่าของกระดาษเดิม');
    expect(t.ext('lyra', 'body'), _res(kBuiltinLyraPaper, Brightness.light).ext('lyra', 'body'), reason: 'ที่ไม่ขึ้นกับ accent คงเดิม');

    final pinned = const NslThemeSpec(
      id: 'p',
      name: 'p',
      extendsId: kBuiltinLyraPaperId,
      light: NslModeSpec(colors: {'accent': red}, extensions: {'lyra': {'accentDark': Color(0xFF123456)}}),
    );
    expect(_res(pinned, Brightness.light).ext('lyra', 'accentDark'), const Color(0xFF123456));

    final dev = const NslThemeSpec(id: 'd', name: 'd', extendsId: kBuiltinDevId, light: NslModeSpec(colors: {'accent': red}));
    final fk = _res(dev, Brightness.light).ext('nebular', 'fkChip');
    expect(fk, isNot(_res(kBuiltinDev, Brightness.light).ext('nebular', 'fkChip')));
    expect(fk, Color.alphaBlend(red.withValues(alpha: 0.2), _res(dev, Brightness.light).colors.surface));
  });

  test('ค่า lite เปลี่ยน accent ก็ล้างคีย์ที่ขึ้นกับ accent เช่นกัน ; ไม่ตั้ง accent = ไม่แตะ', () {
    final paper = _res(kBuiltinLyraPaper, Brightness.dark);
    final lite = _res(kBuiltinLyraPaper.withAppearance(const NslAppearance(presetId: 'green')), Brightness.dark);
    expect(lite.ext('lyra', 'accentDark'), isNot(paper.ext('lyra', 'accentDark')));
    final modeOnly = _res(kBuiltinLyraPaper.withAppearance(const NslAppearance(mode: NslModeChoice.dark)), Brightness.dark);
    expect(modeOnly, paper);
  });

  test('ไฟล์ธีมที่อ้าง extensions.lyra ผ่าน parse → resolve ได้ และไฟล์จาก core 1.0 (ไม่มี lyra) ยังใช้ได้ครบ', () {
    final r = parseNslt('{"schema":1,"core":"1.1","id":"x","name":"X","extends":"nsl.lyra.paper","light":{"extensions":{"lyra":{"typePlace":"#112233"}}}}');
    expect(r.ok, isTrue);
    expect(_res(r.spec!, Brightness.light).ext('lyra', 'typePlace'), const Color(0xFF112233));
    final old = parseNslt('{"schema":1,"core":"1.0","id":"y","name":"Y","extends":"nsl.default"}').spec!;
    expect(_res(old, Brightness.light).ext('lyra', 'typePlace'), isNotNull);
  });
}
