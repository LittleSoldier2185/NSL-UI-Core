// ui-settings.json ใช้ร่วมหลายแอป/หลายรุ่น: การบันทึกต้องไม่ทำคีย์ที่ไม่รู้จักหาย + การลบธีมใน controller
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

void main() {
  late Directory tmp, docs, app;
  final sep = Platform.pathSeparator;
  late NslThemeStore store;
  File settings() => File('${app.path}${sep}ui-settings.json');
  Map<String, dynamic> read() => jsonDecode(settings().readAsStringSync()) as Map<String, dynamic>;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('nsl_preserve');
    docs = Directory('${tmp.path}${sep}Documents')..createSync();
    app = Directory('${tmp.path}${sep}AppData')..createSync();
    store = NslThemeStore.standard(documents: docs, settingsRoot: app);
  });
  tearDown(() async {
    try {
      await tmp.delete(recursive: true);
    } catch (_) {}
  });

  group('saveSettings คงคีย์ที่ไม่รู้จัก', () {
    test('คีย์ของรุ่นอื่น/แอปอื่นอยู่รอด ส่วนที่รู้จักถูกอัปเดต', () async {
      settings().writeAsStringSync('{"schema":1,"activeThemeId":"a","futureKey":{"x":[1,2]},"perApp":{"spectrum":{"theme":"z"}}}');
      await store.saveSettings(const NslUiSettings(activeThemeId: 'b', safeMode: true, appearance: NslAppearance(presetId: 'teal')));
      final j = read();
      expect(j['activeThemeId'], 'b');
      expect(j['safeMode'], true);
      expect((j['appearance'] as Map)['preset'], 'teal');
      expect(j['futureKey'], {'x': [1, 2]});
      expect(j['perApp'], {'spectrum': {'theme': 'z'}});
      expect(settings().parent.listSync().where((e) => e.path.endsWith('.tmp')), isEmpty);
    });

    test('ล้างค่าที่รู้จัก (เลือกธีม = null, lite ค่าเริ่มต้น) แล้วคีย์เหล่านั้นหายไป แต่คีย์ที่ไม่รู้จักยังอยู่', () async {
      settings().writeAsStringSync('{"schema":1,"activeThemeId":"a","appearance":{"mode":"dark"},"keep":1}');
      await store.saveSettings(const NslUiSettings());
      final j = read();
      expect(j.containsKey('activeThemeId'), isFalse);
      expect(j.containsKey('appearance'), isFalse);
      expect(j['keep'], 1);
    });

    test('ไฟล์เดิมเสีย/ไม่ใช่ออบเจ็กต์/ใหญ่เกินไป → เขียนเฉพาะคีย์ที่รู้จัก ไม่โยน และอ่านกลับได้', () async {
      for (final bad in ['not json', '[1,2]', '5', '{"schema":1,"junk":"${'x' * 5000}"}']) {
        settings().writeAsStringSync(bad);
        await store.saveSettings(const NslUiSettings(activeThemeId: 'ok'));
        expect((await store.loadSettings()).activeThemeId, 'ok', reason: bad.length > 20 ? 'big' : bad);
        expect(read().keys.toSet().difference({'schema', 'activeThemeId', 'safeMode'}), isEmpty, reason: 'ไม่ควรเหลือคีย์แปลกปลอม');
      }
    });

    test('คีย์ที่ไม่รู้จักมากจนไฟล์เกิน 4 KB หลังรวม → ทิ้งคีย์เหล่านั้น (ไม่ให้ไฟล์โตจนอ่านไม่ได้)', () async {
      settings().writeAsStringSync('{"schema":1,"big":"${'y' * 3900}"}');
      await store.saveSettings(const NslUiSettings(activeThemeId: 'abc', safeMode: true));
      expect(settings().lengthSync(), lessThan(4096));
      expect((await store.loadSettings()).activeThemeId, 'abc');
    });

    test('ผ่านตัวควบคุม: เลือกธีม + ตั้ง lite หลายรอบ คีย์ของรุ่นอื่นยังอยู่', () async {
      settings().writeAsStringSync('{"schema":1,"newer":{"v":2}}');
      await store.saveTheme(parseNslt('{"schema":1,"id":"mine","name":"Mine","extends":"nsl.default"}').spec!);
      final c = NslThemeController(store);
      await c.reload();
      await c.select('mine');
      await c.setAppearance(const NslAppearance(presetId: 'blue'));
      await c.setSafeMode(true);
      await c.setSafeMode(false);
      final j = read();
      expect(j['newer'], {'v': 2});
      expect(j['activeThemeId'], 'mine');
      c.dispose();
    });
  });

  group('NslThemeController.deleteTheme', () {
    NslThemeSpec spec(String id) => parseNslt('{"schema":1,"id":"$id","name":"$id","extends":"nsl.default"}').spec!;

    test('ลบธีมที่ไม่ได้ใช้: ไฟล์หาย รายการอัปเดต ตัวเลือกเดิมคงอยู่', () async {
      await store.saveTheme(spec('a'));
      await store.saveTheme(spec('b'));
      final c = NslThemeController(store);
      await c.reload();
      await c.select('a');
      await c.deleteTheme('b');
      expect(File('${store.themesDir.path}${sep}b.nslt').existsSync(), isFalse);
      expect(c.userThemes.map((t) => t.id), ['a']);
      expect(c.settings.activeThemeId, 'a');
      c.dispose();
    });

    test('ลบธีมที่เลือกใช้อยู่: ล้างตัวเลือก (กลับธีมในตัวของแอป) และบันทึกลงไฟล์ค่าตั้งทันที ไม่มี "ธีมที่เลือกหาย" ค้าง', () async {
      await store.saveTheme(spec('a'));
      final c = NslThemeController(store);
      await c.reload();
      await c.select('a');
      await c.deleteTheme('a');
      expect(c.settings.activeThemeId, isNull);
      expect(c.activeSpec, isNull);
      expect(c.problems, isEmpty);
      expect((await store.loadSettings()).activeThemeId, isNull);
      c.dispose();
    });

    test('id ผิดรูปแบบ/สงวน/ไม่มีอยู่ → ไม่ทำอะไร ไม่โยน และไม่แตะไฟล์อื่น', () async {
      await store.saveTheme(spec('keep'));
      final c = NslThemeController(store);
      await c.reload();
      for (final id in ['../keep', 'a/b', 'nsl.nebular', 'nsl.default', '', 'ghost', 'UPPER']) {
        await c.deleteTheme(id);
      }
      expect(File('${store.themesDir.path}${sep}keep.nslt').existsSync(), isTrue);
      expect(c.userThemes.map((t) => t.id), ['keep']);
      c.dispose();
    });
  });
}
