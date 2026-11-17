import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

NslThemeSpec _spec(String id, {String? ext, String accent = '#1D4ED8'}) => parseNslt(
      '{"schema":1,"id":"$id","name":"$id",${ext == null ? '' : '"extends":"$ext",'}'
      '"light":{"colors":{"accent":"$accent"}}}',
    ).spec!;

void main() {
  late Directory tmp;
  late NslThemeStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('nsl_store_test_');
    store = NslThemeStore(Directory('${tmp.path}${Platform.pathSeparator}NSL'));
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('NslThemeStore', () {
    test('ยังไม่มีโฟลเดอร์ = ว่าง ไม่โยน', () async {
      final s = await store.loadAll();
      expect(s.themes, isEmpty);
      expect(s.problems, isEmpty);
      expect((await store.loadSettings()).activeThemeId, isNull);
    });

    test('บันทึกแล้วอ่านกลับได้ และไม่ทิ้งไฟล์ .tmp', () async {
      await store.saveTheme(_spec('ocean', ext: 'nsl.nebular'));
      final s = await store.loadAll();
      expect(s.themes.keys, ['ocean']);
      expect(s.themes['ocean']!.extendsId, 'nsl.nebular');
      expect(store.themesDir.listSync().map((e) => e.path).where((p) => p.endsWith('.tmp')), isEmpty);
    });

    test('บันทึกทับ = ค่าใหม่', () async {
      await store.saveTheme(_spec('ocean', ext: 'nsl.nebular', accent: '#112233'));
      await store.saveTheme(_spec('ocean', ext: 'nsl.nebular', accent: '#445566'));
      final s = await store.loadAll();
      expect(s.themes['ocean']!.light.colors['accent'], const Color(0xFF445566));
    });

    test('id ไม่ปลอดภัย/สงวน: saveTheme ปฏิเสธ (กัน path traversal และการทับธีมในตัว)', () async {
      for (final bad in ['../evil', 'a/b', r'a\b', 'nsl.nebular', 'UPPER', '']) {
        // สร้าง spec ตรง ๆ เพื่อข้าม parser
        final spec = NslThemeSpec(id: bad, name: 'x');
        await expectLater(store.saveTheme(spec), throwsArgumentError, reason: bad);
      }
      expect(await tmp.list(recursive: true).where((e) => e.path.contains('evil')).isEmpty, isTrue);
    });

    test('ไฟล์ที่ไม่ปลอดภัยถูกข้ามพร้อมเหตุผล ส่วนไฟล์ดียังใช้ได้', () async {
      await store.saveTheme(_spec('good', ext: 'nsl.nebular'));
      final d = store.themesDir;
      File('${d.path}/broken.nslt').writeAsStringSync('{not json');
      File('${d.path}/mismatch.nslt').writeAsStringSync(serializeNslt(_spec('other', ext: 'nsl.nebular')));
      File('${d.path}/nsl.nebular.nslt').writeAsStringSync(
          '{"schema":1,"id":"nsl.nebular","name":"fake","light":{"colors":{"accent":"#000000"}}}');
      File('${d.path}/huge.nslt').writeAsBytesSync(List.filled(kNsltMaxBytes + 1, 0x20));
      File('${d.path}/readme.txt').writeAsStringSync('ignore me');
      final s = await store.loadAll();
      expect(s.themes.keys, ['good']);
      expect(s.problems.length, 4);
      expect(s.problems.join('\n'), allOf(contains('broken.nslt'), contains('mismatch.nslt'), contains('reserved'), contains('too large')));
    });

    test('ui-settings.json: เสีย/ใหญ่เกิน/id แปลก = ค่าเริ่มต้น', () async {
      expect(NslUiSettings.parse('xx').activeThemeId, isNull);
      expect(NslUiSettings.parse('[1,2]').safeMode, isFalse);
      expect(NslUiSettings.parse('{"activeThemeId":"../x","safeMode":true}').activeThemeId, isNull);
      expect(NslUiSettings.parse('{"activeThemeId":"ok","safeMode":true}').safeMode, isTrue);
      expect(NslUiSettings.parse('{"a":"${'x' * 5000}"}').activeThemeId, isNull);
      await store.saveSettings(const NslUiSettings(activeThemeId: 'ocean', safeMode: true));
      final back = await store.loadSettings();
      expect(back.activeThemeId, 'ocean');
      expect(back.safeMode, isTrue);
    });

    test('defaultRoot ใช้ APPDATA/NSL บน Windows และคืน null ถ้าไม่มี', () {
      if (Platform.isWindows) {
        expect(NslThemeStore.defaultRoot({'APPDATA': r'C:\X'})!.path, r'C:\X\NSL');
        expect(NslThemeStore.defaultRoot({}), isNull);
      }
    });

    test('watch: การเขียนธีมจาก "อีกแอป" ทำให้มีเหตุการณ์ (รวมเป็นอันเดียว)', () async {
      final events = <void>[];
      final sub = store.watch(debounce: const Duration(milliseconds: 50)).listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final other = NslThemeStore(store.root); // อีกอินสแตนซ์ = อีกโปรเซส
      await other.saveTheme(_spec('ocean', ext: 'nsl.nebular'));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await sub.cancel();
      expect(events, isNotEmpty);
      expect(events.length, lessThanOrEqualTo(2));
    });
  });

  group('NslThemeController', () {
    test('เลือกธีมแล้ว activeSpec ตรง และบันทึกลง ui-settings.json', () async {
      await store.saveTheme(_spec('ocean', ext: 'nsl.nebular'));
      final c = NslThemeController(store);
      await c.reload();
      expect(c.activeSpec, isNull);
      await c.select('ocean');
      expect(c.activeSpec!.id, 'ocean');
      expect((await store.loadSettings()).activeThemeId, 'ocean');
      c.dispose();
    });

    test('safe mode: ไม่ใช้ธีมผู้ใช้ แม้เลือกไว้ ; ปิดแล้วกลับมา', () async {
      await store.saveTheme(_spec('ocean', ext: 'nsl.nebular'));
      final c = NslThemeController(store);
      await c.reload();
      await c.select('ocean');
      await c.setSafeMode(true);
      expect(c.activeSpec, isNull);
      expect(c.safeMode, isTrue);
      await c.setSafeMode(false);
      expect(c.activeSpec!.id, 'ocean');
      c.dispose();
    });

    test('ธีมที่เลือกใช้ไม่ได้ (ฐานหาย) หรือไฟล์หาย → activeSpec เป็น null พร้อมเหตุผล ไม่โยน', () async {
      await store.saveTheme(_spec('orphan', ext: 'ghost'));
      final c = NslThemeController(store);
      await c.reload();
      await c.select('orphan');
      expect(c.activeSpec, isNull);
      expect(c.problems.join(), contains('unusable'));
      await c.select('missing');
      expect(c.activeSpec, isNull);
      expect(c.problems.join(), contains('not found'));
      c.dispose();
    });

    test('ธีมที่ extends ธีมผู้ใช้อีกไฟล์ resolve ได้', () async {
      await store.saveTheme(_spec('base', ext: 'nsl.nebular', accent: '#aa3355'));
      await store.saveTheme(_spec('child', ext: 'base'));
      final c = NslThemeController(store);
      await c.reload();
      await c.select('child');
      expect(c.activeSpec!.id, 'child');
      c.dispose();
    });

    test('สองแอป: แอปหนึ่งเขียนธีม อีกแอปเห็นสดผ่าน watcher และได้รับแจ้ง', () async {
      final resonance = NslThemeController(NslThemeStore(store.root));
      await resonance.reload();
      resonance.startWatching(debounce: const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      var notified = 0;
      resonance.addListener(() => notified++);

      final dev = NslThemeController(store);
      await dev.reload();
      await store.saveTheme(_spec('ocean', ext: 'nsl.nebular', accent: '#112233'));
      await dev.select('ocean');

      await _until(() => resonance.activeSpec?.id == 'ocean');
      expect(notified, greaterThan(0));
      expect(resonance.activeSpec!.light.colors['accent'], const Color(0xFF112233));

      // แก้ธีมที่ใช้อยู่ → อีกแอปได้ค่าใหม่
      await store.saveTheme(_spec('ocean', ext: 'nsl.nebular', accent: '#778899'));
      await _until(() => resonance.activeSpec?.light.colors['accent'] == const Color(0xFF778899));

      resonance.dispose();
      dev.dispose();
    });

    test('ไฟล์ธีมถูกทำให้เสียกลางทาง: ถอยไปธีมในตัว (null) ไม่ล้ม', () async {
      await store.saveTheme(_spec('ocean', ext: 'nsl.nebular'));
      final c = NslThemeController(store);
      await c.reload();
      await c.select('ocean');
      File('${store.themesDir.path}/ocean.nslt').writeAsStringSync('garbage');
      await c.reload();
      expect(c.activeSpec, isNull);
      expect(c.problems, isNotEmpty);
      c.dispose();
    });
  });
}

Future<void> _until(bool Function() cond, {Duration timeout = const Duration(seconds: 5)}) async {
  final end = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(end)) fail('timeout waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
