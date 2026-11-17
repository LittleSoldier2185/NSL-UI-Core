// ตำแหน่งที่เก็บมาตรฐาน: ไฟล์ธีมที่ Documents\NSL\Themes (ผู้ใช้เข้าถึงง่าย) แยกจากค่าตั้งภายใน (APPDATA)
// ใช้โฟลเดอร์ชั่วคราวเสมอ ไม่เขียน Documents/APPDATA จริง
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

NslThemeSpec _spec(String id, {String accent = '#112233'}) => parseNslt(
      '{"schema":1,"id":"$id","name":"$id","extends":"nsl.nebular","light":{"colors":{"accent":"$accent"}}}',
    ).spec!;

void main() {
  late Directory tmp, docs, appdata;
  final sep = Platform.pathSeparator;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('nsl_layout');
    docs = Directory('${tmp.path}${sep}Documents')..createSync();
    appdata = Directory('${tmp.path}${sep}AppData')..createSync();
  });
  tearDown(() async {
    try {
      await tmp.delete(recursive: true);
    } catch (_) {}
  });

  group('NslThemeStore.standard', () {
    test('ไฟล์ธีมอยู่ที่ Documents/NSL/Themes ; ค่าตั้งอยู่ที่ settingsRoot ; ไม่มีอะไรหลุดไปที่อื่น', () async {
      final st = NslThemeStore.standard(documents: docs, settingsRoot: appdata);
      expect(st.themesDir.path, '${docs.path}${sep}NSL${sep}Themes');
      await st.saveTheme(_spec('sea'));
      await st.saveSettings(const NslUiSettings(activeThemeId: 'sea'));

      expect(File('${docs.path}${sep}NSL${sep}Themes${sep}sea.nslt').existsSync(), isTrue);
      expect(File('${appdata.path}${sep}ui-settings.json').existsSync(), isTrue);
      // ค่าตั้งไม่ไปอยู่ใน Documents และไฟล์ธีมไม่ไปอยู่ใน AppData
      expect(File('${docs.path}${sep}NSL${sep}ui-settings.json').existsSync(), isFalse);
      expect(Directory('${appdata.path}${sep}themes').existsSync(), isFalse);
      expect(docs.listSync().map((e) => e.path.split(sep).last).toList(), ['NSL']);
      expect(Directory('${docs.path}${sep}NSL').listSync().map((e) => e.path.split(sep).last).toList(), ['Themes']);
      // ไม่เหลือไฟล์ชั่วคราว (เขียนแบบ atomic)
      expect(st.themesDir.listSync().where((e) => e.path.endsWith('.tmp')), isEmpty);
    });

    test('โหลดกลับได้ทั้งธีมและค่าตั้ง ; ผู้ใช้วางไฟล์ลงโฟลเดอร์เองก็เห็น (นี่คือเหตุผลที่ใช้ Documents)', () async {
      final st = NslThemeStore.standard(documents: docs, settingsRoot: appdata);
      await st.saveSettings(const NslUiSettings(activeThemeId: 'hand', safeMode: true, appearance: NslAppearance(presetId: 'teal')));
      st.themesDir.createSync(recursive: true);
      File('${st.themesDir.path}${sep}hand.nslt').writeAsStringSync(serializeNslt(_spec('hand', accent: '#445566')));

      final snap = await st.loadAll();
      expect(snap.themes.keys, ['hand']);
      expect(snap.problems, isEmpty);
      final s = await st.loadSettings();
      expect(s.activeThemeId, 'hand');
      expect(s.safeMode, isTrue);
      expect(s.appearance.presetId, 'teal');
    });

    test('ไม่ระบุ settingsRoot และหา APPDATA ไม่ได้ → ค่าตั้งไปอยู่ข้างไฟล์ธีมใต้ Documents/NSL (ไม่ล้ม)', () async {
      final st = NslThemeStore.standard(documents: docs, env: const {});
      await st.saveSettings(const NslUiSettings(activeThemeId: 'x'));
      expect(File('${docs.path}${sep}NSL${sep}ui-settings.json').existsSync(), isTrue);
      expect((await st.loadSettings()).activeThemeId, 'x');
    });

    test('กติกาความปลอดภัยเดิมยังใช้: id สงวน/มี path ถูกปฏิเสธ, ไฟล์ชื่อไม่ตรง id หรือ id สงวนถูกข้ามพร้อมเหตุผล, symlink ไม่ถูกตาม', () async {
      final st = NslThemeStore.standard(documents: docs, settingsRoot: appdata);
      for (final bad in ['nsl.nebular', '../evil', 'a/b']) {
        expect(() => st.saveTheme(NslThemeSpec(id: bad, name: 'x')), throwsArgumentError, reason: bad);
      }
      st.themesDir.createSync(recursive: true);
      File('${st.themesDir.path}${sep}mismatch.nslt').writeAsStringSync(serializeNslt(_spec('other')));
      File('${st.themesDir.path}${sep}nsl.nebular.nslt').writeAsStringSync('{"schema":1,"id":"nsl.nebular","name":"fake"}');
      File('${st.themesDir.path}${sep}big.nslt').writeAsStringSync('x' * (kNsltMaxBytes + 10));
      final snap = await st.loadAll();
      expect(snap.themes, isEmpty);
      expect(snap.problems.length, 3);
    });
  });

  group('ตัวสร้างเดิม (Android และเทสต์) ไม่เปลี่ยนพฤติกรรม', () {
    test('NslThemeStore(dir): ธีมอยู่ <dir>/themes และค่าตั้งอยู่ <dir>/ui-settings.json', () async {
      final st = NslThemeStore(appdata);
      expect(st.themesDir.path, '${appdata.path}${sep}themes');
      await st.saveTheme(_spec('a'));
      await st.saveSettings(const NslUiSettings(activeThemeId: 'a'));
      expect(File('${appdata.path}${sep}themes${sep}a.nslt').existsSync(), isTrue);
      expect(File('${appdata.path}${sep}ui-settings.json').existsSync(), isTrue);
    });
  });

  group('watcher เมื่อไฟล์ธีมกับค่าตั้งอยู่คนละโฟลเดอร์', () {
    Future<bool> fires(NslThemeStore st, Future<void> Function() act) async {
      final got = Completer<void>();
      final sub = st.watch(debounce: const Duration(milliseconds: 50)).listen((_) {
        if (!got.isCompleted) got.complete();
      });
      await Future<void>.delayed(const Duration(milliseconds: 200)); // ให้การดูโฟลเดอร์เริ่มก่อน
      await act();
      final ok = await got.future.timeout(const Duration(seconds: 5), onTimeout: () {}).then((_) => true).catchError((_) => false);
      await sub.cancel();
      return got.isCompleted && ok;
    }

    test('แอปอื่นเขียนไฟล์ธีมลง Documents/NSL/Themes → เรารู้', () async {
      final mine = NslThemeStore.standard(documents: docs, settingsRoot: appdata);
      final other = NslThemeStore.standard(documents: docs, settingsRoot: appdata);
      expect(await fires(mine, () => other.saveTheme(_spec('fromother'))), isTrue);
    });

    test('แอปอื่นเปลี่ยนค่าตั้ง (เลือกธีมใหม่) ใน AppData → เรารู้', () async {
      final mine = NslThemeStore.standard(documents: docs, settingsRoot: appdata);
      final other = NslThemeStore.standard(documents: docs, settingsRoot: appdata);
      expect(await fires(mine, () => other.saveSettings(const NslUiSettings(activeThemeId: 'z'))), isTrue);
    });

    test('ตัวควบคุมสองแอป: แอป A นำเข้าธีมแล้วเลือก → แอป B เห็นธีมและตัวเลือกสด (ผ่านสองโฟลเดอร์)', () async {
      final a = NslThemeController(NslThemeStore.standard(documents: docs, settingsRoot: appdata));
      final b = NslThemeController(NslThemeStore.standard(documents: docs, settingsRoot: appdata));
      await a.reload();
      await b.reload();
      b.startWatching(debounce: const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final changed = Completer<void>();
      b.addListener(() {
        if (b.activeSpec?.id == 'shared' && !changed.isCompleted) changed.complete();
      });
      final r = await a.importThemeText(serializeNslt(_spec('shared', accent: '#0369A1')));
      expect(r.ok, isTrue);
      await a.select('shared');
      await changed.future.timeout(const Duration(seconds: 6));
      expect(b.userThemes.map((t) => t.id), ['shared']);
      final t = resolveTokens(b.effective(kBuiltinDev), Brightness.light, lookup: b.lookup);
      expect(t.colors.accent, const Color(0xFF0369A1));
      b.dispose();
      a.dispose();
    });
  });
}
