// ที่เก็บฟอนต์ของผู้ใช้ : นำเข้า/ตรวจ/ลงทะเบียน/ลบ/จัดลำดับ — ไฟล์ในโฟลเดอร์ถือเป็นข้อมูลไม่น่าเชื่อถือ
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

import 'fonts_test.dart' show fakeFont;

const _latin = [(0x20, 0x7E)];
const _thai = [(0x0E01, 0x0E5B)];

void main() {
  late Directory tmp;
  late Directory dir;
  late List<String> registered;

  NslFontStore store({bool failRegister = false}) => NslFontStore(dir, register: (family, bytes) async {
        if (failRegister) throw StateError('engine refused the font');
        registered.add(family);
      });

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('nsl_fonts_');
    dir = Directory('${tmp.path}${Platform.pathSeparator}Fonts');
    registered = [];
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  List<String> files() => dir.existsSync() ? [for (final f in dir.listSync()) f.uri.pathSegments.last] : [];

  group('importFont', () {
    test('a good font is saved under a generated name and registered', () async {
      final s = store();
      final r = await s.importFont(fakeFont(ranges: _latin, name: 'My Sans'));
      expect(r.isOk, isTrue, reason: r.error);
      expect(r.font!.family, 'My Sans');
      expect(r.font!.fileName, matches(RegExp(r'^font-[0-9a-f]{8}\.ttf$')));
      expect(files(), [r.font!.fileName]);
      expect(registered, ['My Sans']);
      expect(s.infos.keys, ['My Sans']);
    });

    test('importing the same family again replaces the file', () async {
      final s = store();
      await s.importFont(fakeFont(ranges: _latin, name: 'My Sans'));
      final r = await s.importFont(fakeFont(ranges: [..._latin, ..._thai], name: 'My Sans'));
      expect(r.isOk, isTrue);
      expect(files().length, 1);
      expect((await s.list()).single.info.coversThai, isTrue);
    });

    test('rejects what is not a font, and writes nothing', () async {
      final s = store();
      final r = await s.importFont(Uint8List.fromList(List.filled(200, 7)));
      expect(r.isOk, isFalse);
      expect(files(), isEmpty);
      expect(registered, isEmpty);
    });

    test('rejects a family that would shadow a built-in fallback font', () async {
      final s = store();
      for (final n in ['Tahoma', 'Noto Sans Thai', 'segoe ui']) {
        final r = await s.importFont(fakeFont(ranges: _latin, name: n));
        expect(r.error, contains('reserved'), reason: n);
      }
      expect(files(), isEmpty);
    });

    test('rejects a font whose name cannot be read', () async {
      final b = fakeFont(ranges: _latin, name: '///');
      final r = await store().importFont(b);
      expect(r.isOk, isFalse);
    });

    test('the file name never contains anything from the font name', () async {
      final r = await store().importFont(fakeFont(ranges: _latin, name: '..Evil Name'));
      expect(r.font!.fileName, matches(RegExp(r'^font-[0-9a-f]{8}\.ttf$')));
      expect(files().every((f) => !f.contains('Evil')), isTrue);
    });

    test('a font the engine refuses is saved but not counted as loaded', () async {
      final s = store(failRegister: true);
      await s.importFont(fakeFont(ranges: _latin, name: 'Odd'));
      expect(s.infos, isEmpty);
    });

    test('the number of fonts is capped', () async {
      final s = store();
      for (var i = 0; i < kMaxUserFonts; i++) {
        expect((await s.importFont(fakeFont(ranges: _latin, name: 'Font $i'))).isOk, isTrue, reason: '$i');
      }
      final r = await s.importFont(fakeFont(ranges: _latin, name: 'One too many'));
      expect(r.error, contains('too many'));
      // replacing an existing one is still allowed at the cap
      expect((await s.importFont(fakeFont(ranges: _latin, name: 'Font 3'))).isOk, isTrue);
    });
  });

  group('folder contents (untrusted)', () {
    void put(String name, List<int> bytes) {
      dir.createSync(recursive: true);
      File('${dir.path}${Platform.pathSeparator}$name').writeAsBytesSync(bytes);
    }

    test('loadAll registers valid fonts and reports the rest', () async {
      put('a.ttf', fakeFont(ranges: _latin, name: 'Alpha'));
      put('b.OTF', fakeFont(ranges: [..._latin, ..._thai], name: 'Beta'));
      put('broken.ttf', List.filled(300, 1));
      put('notes.txt', [1, 2, 3]);
      put('c.ttf.tmp', fakeFont(ranges: _latin, name: 'Gamma'));
      final s = store();
      final problems = await s.loadAll();
      expect(registered.toSet(), {'Alpha', 'Beta'});
      expect(problems.single, contains('broken.ttf'));
      expect(s.infos['Beta']!.coversThai, isTrue);
    });

    test('two files with the same family: the first wins', () async {
      put('a.ttf', fakeFont(ranges: _latin, name: 'Same'));
      put('b.ttf', fakeFont(ranges: _latin, name: 'Same'));
      final problems = <String>[];
      final l = await store().list(problems: problems);
      expect(l.length, 1);
      expect(problems.single, contains('already provided'));
    });

    test('a reserved family in the folder is skipped', () async {
      put('t.ttf', fakeFont(ranges: _latin, name: 'Tahoma'));
      final problems = <String>[];
      expect(await store().list(problems: problems), isEmpty);
      expect(problems.single, contains('reserved'));
    });

    test('an oversized file is skipped without being read into memory', () async {
      dir.createSync(recursive: true);
      final f = File('${dir.path}${Platform.pathSeparator}huge.ttf');
      final raf = f.openSync(mode: FileMode.write);
      raf.truncateSync(kMaxFontBytes + 1); // sparse: no real data
      raf.closeSync();
      final problems = <String>[];
      expect(await store().list(problems: problems), isEmpty);
      expect(problems.single, contains('too large'));
    });

    test('a missing folder is just empty', () async {
      expect(await store().list(), isEmpty);
      expect(await store().loadAll(), isEmpty);
    });

    test('a symlink is not followed', () async {
      final real = File('${tmp.path}${Platform.pathSeparator}outside.ttf')..writeAsBytesSync(fakeFont(ranges: _latin, name: 'Outside'));
      dir.createSync(recursive: true);
      try {
        Link('${dir.path}${Platform.pathSeparator}link.ttf').createSync(real.path);
      } on FileSystemException {
        markTestSkipped('symlinks are not permitted on this machine');
        return;
      }
      final problems = <String>[];
      expect(await store().list(problems: problems), isEmpty);
      expect(problems.single, contains('not a regular file'));
    });

    test('a failing registration is reported, other fonts still load', () async {
      put('a.ttf', fakeFont(ranges: _latin, name: 'Alpha'));
      final s = store(failRegister: true);
      final problems = await s.loadAll();
      expect(problems.single, contains('cannot be loaded'));
      expect(s.infos, isEmpty);
    });
  });

  group('remove', () {
    test('removes the file of that family only', () async {
      final s = store();
      await s.importFont(fakeFont(ranges: _latin, name: 'Keep'));
      await s.importFont(fakeFont(ranges: _latin, name: 'Drop'));
      expect(await s.remove('Drop'), isTrue);
      expect((await s.list()).map((f) => f.family), ['Keep']);
      expect(s.infos.keys, ['Keep']); // a removed font no longer counts in the plan/list
      expect(await s.remove('Nope'), isFalse);
      expect(await s.remove('../../etc/passwd'), isFalse);
    });
  });

  group('adapt / reportFor', () {
    Future<NslFontStore> loaded() async {
      final s = store();
      await s.importFont(fakeFont(ranges: _latin, name: 'LatinOnly'));
      await s.importFont(fakeFont(ranges: _thai, name: 'ThaiOnly'));
      await s.importFont(fakeFont(ranges: [..._latin, ..._thai], name: 'Both'));
      return s;
    }

    test('Latin font without Thai + Thai font: nothing to change', () async {
      final s = await loaded();
      const t = NslType(family: 'LatinOnly', familyThai: 'ThaiOnly');
      expect(s.reportFor(t).hasIssues, isFalse);
      expect(s.adapt(t).thaiFirst, isEmpty);
    });

    test('Latin font that also has Thai + Thai-only font: Thai first', () async {
      final s = await loaded();
      const t = NslType(family: 'Both', familyThai: 'ThaiOnly');
      final a = s.adapt(t);
      expect(a.thaiFirst, {'family'});
      expect(a.effectiveFamily, 'ThaiOnly');
      expect(a.fallback.first, 'Both');
    });

    test('two fonts that both cover both scripts are reported', () async {
      final s = await loaded();
      final r = s.reportFor(const NslType(family: 'Both', familyThai: 'Both2'));
      expect(r.hasIssues, isFalse); // Both2 is unknown → not judged
      await s.importFont(fakeFont(ranges: [..._latin, ..._thai], name: 'Both2'));
      final r2 = s.reportFor(const NslType(family: 'Both', familyThai: 'Both2'));
      expect(r2.issues['family'], [NslFontIssue.bothCoverBoth]);
    });

    test('a Thai slot that has no Thai letters is reported per role', () async {
      final s = await loaded();
      final r = s.reportFor(const NslType(contentThai: 'LatinOnly'));
      expect(r.issues['content'], [NslFontIssue.thaiFontLacksThai]);
      expect(r.issues.containsKey('family'), isFalse);
    });

    test('fonts that are not user files are not judged', () async {
      final s = await loaded();
      final t = const NslType(family: 'Inter', familyThai: 'Sarabun');
      expect(s.reportFor(t).hasIssues, isFalse);
      expect(identical(s.adapt(t), t), isTrue);
    });
  });
}
