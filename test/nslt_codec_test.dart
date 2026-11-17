import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

const _sample = '''
{
  "schema": 1,
  "id": "my-teal",
  "name": "My Teal",
  "extends": "nsl.default",
  "light": {
    "colors": { "accent": "#0F766E", "bg": "#EEF1F5" },
    "extensions": { "nebular": { "tableHead": "#1F2A37" } }
  },
  "dark": { "colors": { "accent": "#14958B80" } },
  "shape": { "radius": { "md": 10, "pill": 999 } },
  "type": { "family": "Noto Sans Thai", "scale": 1.1 },
  "density": "compact",
  "elevation": { "mode": "flat", "strength": 0.5 }
}
''';

void main() {
  group('parseNslt', () {
    test('ไฟล์ตัวอย่างอ่านได้ครบทุกฟิลด์ ไม่มีคำเตือน', () {
      final r = parseNslt(_sample);
      expect(r.ok, isTrue, reason: r.errors.join(';'));
      expect(r.warnings, isEmpty);
      final s = r.spec!;
      expect(s.id, 'my-teal');
      expect(s.name, 'My Teal');
      expect(s.extendsId, 'nsl.default');
      expect(s.light.colors['accent'], const Color(0xFF0F766E));
      expect(s.dark.colors['accent'], const Color(0x8014958B)); // #RRGGBBAA → alpha 0x80
      expect(s.light.extensions['nebular']!['tableHead'], const Color(0xFF1F2A37));
      expect(s.radius, {'md': 10.0, 'pill': 999.0});
      expect(s.family, 'Noto Sans Thai');
      expect(s.scale, 1.1);
      expect(s.density, NslDensity.compact);
      expect(s.elevationMode, NslElevationMode.flat);
      expect(s.elevationStrength, 0.5);
    });

    test('เขียนแล้วอ่านกลับได้เท่าเดิม (round trip) และเขียนซ้ำได้ข้อความเดิม', () {
      final s = parseNslt(_sample).spec!;
      final text = serializeNslt(s);
      final again = parseNslt(text);
      expect(again.ok, isTrue);
      expect(again.warnings, isEmpty);
      expect(serializeNslt(again.spec!), text);
    });

    test('ธีมในตัวเขียนแล้วอ่านกลับ resolve ได้ค่าเท่าเดิม (เทียบที่ 8 บิตต่อช่อง ตามที่ไฟล์เก็บ)', () {
      // inkFor ใช้ Color.lerp ซึ่งได้ค่าช่องเป็นทศนิยม ไฟล์เก็บ 8 บิตจึงต่างกันระดับเศษทศนิยมที่ตามองไม่เห็น
      Map<String, int> flat(NslTokens t) => {
            for (final e in t.colors.toMap().entries) 'core.${e.key}': e.value.toARGB32(),
            for (final x in t.extensions.entries)
              for (final e in x.value.entries) '${x.key}.${e.key}': e.value.toARGB32(),
          };
      for (final spec in [kBuiltinDev, builtinResonance()]) {
        final back = parseNslt(serializeNslt(spec)).spec!;
        for (final b in Brightness.values) {
          final a = resolveTokens(spec, b), c = resolveTokens(back, b);
          expect(flat(c), flat(a), reason: '${spec.id} $b');
          expect(c.shape, a.shape);
          expect(c.type, a.type);
          expect(c.density, a.density);
          expect(c.elevation, a.elevation);
        }
      }
    });

    test('เขียนแล้วอ่านกลับซ้ำหลายรอบไม่คลาดเคลื่อนสะสม (idempotent หลังรอบแรก)', () {
      final first = serializeNslt(parseNslt(serializeNslt(builtinResonance())).spec!);
      final second = serializeNslt(parseNslt(first).spec!);
      expect(second, first);
    });

    test('คีย์ที่ไม่รู้จักระดับบนสุดถูกเก็บและเขียนกลับ', () {
      final r = parseNslt('{"schema":1,"id":"a","name":"A","futureThing":{"x":[1,2,3]}}');
      expect(r.spec!.unknown['futureThing'], {'x': [1, 2, 3]});
      expect(serializeNslt(r.spec!), contains('futureThing'));
    });

    test('คีย์สี/ส่วนขยายที่ไม่รู้จักถูกเก็บไว้ (รุ่นเก่าไม่ทำของรุ่นใหม่หาย)', () {
      final r = parseNslt('{"schema":1,"id":"a","name":"A","light":{"colors":{"newToken":"#112233"},"extensions":{"future":{"k":"#445566"}}}}');
      final text = serializeNslt(r.spec!);
      expect(text, contains('newToken'));
      expect(text, contains('future'));
    });

    test('schema ใหม่กว่าที่รู้ → ปฏิเสธพร้อมข้อความ', () {
      final r = parseNslt('{"schema":99,"id":"a","name":"A"}');
      expect(r.ok, isFalse);
      expect(r.errors.single, contains('newer'));
    });

    test('schema/ id ผิด → ปฏิเสธ', () {
      expect(parseNslt('{"id":"a","name":"A"}').ok, isFalse);
      expect(parseNslt('{"schema":"1","id":"a","name":"A"}').ok, isFalse);
      expect(parseNslt('{"schema":0,"id":"a","name":"A"}').ok, isFalse);
      expect(parseNslt('{"schema":1,"name":"A"}').ok, isFalse);
      expect(parseNslt('{"schema":1,"id":"Has Space","name":"A"}').ok, isFalse);
      expect(parseNslt('{"schema":1,"id":"../evil","name":"A"}').ok, isFalse);
    });

    test('ไม่ใช่ JSON / ไม่ใช่ object / ว่าง → ปฏิเสธ ไม่โยน', () {
      expect(parseNslt('').ok, isFalse);
      expect(parseNslt('not json').ok, isFalse);
      expect(parseNslt('[1,2,3]').ok, isFalse);
      expect(parseNslt('"x"').ok, isFalse);
      expect(parseNslt('null').ok, isFalse);
    });

    test('ไฟล์ใหญ่เกิน 64 KB → ปฏิเสธ', () {
      final big = '{"schema":1,"id":"a","name":"${'x' * (kNsltMaxBytes + 1)}"}';
      final r = parseNslt(big);
      expect(r.ok, isFalse);
      expect(r.errors.single, contains('too large'));
    });

    test('ขนาดนับเป็นไบต์ ไม่ใช่ตัวอักษร (ไทย 3 ไบต์/ตัว)', () {
      final thai = 'ก' * (kNsltMaxBytes ~/ 3 + 10);
      expect(parseNslt('{"schema":1,"id":"a","name":"$thai"}').ok, isFalse);
    });

    test('สีรูปแบบผิดถูกข้ามพร้อมคำเตือน ส่วนที่ถูกยังใช้ได้', () {
      final r = parseNslt('{"schema":1,"id":"a","name":"A","light":{"colors":{"bg":"red","text":"#12345","accent":"#0F766E","border":123,"surface":"#FFFFFF"}}}');
      expect(r.ok, isTrue);
      expect(r.spec!.light.colors.keys.toSet(), {'accent', 'surface'});
      expect(r.warnings.length, 3);
    });

    test('ตัวเลขนอกช่วงถูก clamp พร้อมคำเตือน', () {
      final r = parseNslt('{"schema":1,"id":"a","name":"A","type":{"scale":5},"elevation":{"strength":-3},"shape":{"radius":{"md":100000}}}');
      expect(r.spec!.scale, NslType.maxScale);
      expect(r.spec!.elevationStrength, NslElevation.minStrength);
      expect(r.spec!.radius['md'], NslShape.maxRadius);
      expect(r.warnings.length, 3);
    });

    test('Infinity (1e999) และ NaN ไม่ผ่านเป็นตัวเลข', () {
      final r = parseNslt('{"schema":1,"id":"a","name":"A","type":{"scale":1e999},"elevation":{"strength":1e999}}');
      expect(r.ok, isTrue);
      expect(r.spec!.scale, isNull);
      expect(r.spec!.elevationStrength, isNull);
      expect(r.warnings.length, 2);
    });

    test('ชื่อฟอนต์ที่มี path/อักขระควบคุมถูกปฏิเสธ', () {
      for (final bad in [r'C:\\Windows\\evil', 'a/b', 'a:b', 'x\\u0000y', '', 'ก' * 100]) {
        final r = parseNslt(jsonEncode({'schema': 1, 'id': 'a', 'name': 'A', 'type': {'family': bad}}));
        expect(r.spec!.family, isNull, reason: bad);
        expect(r.warnings, isNotEmpty, reason: bad);
      }
    });

    test('density/mode ที่ไม่รู้จักถูกข้ามพร้อมคำเตือน', () {
      final r = parseNslt('{"schema":1,"id":"a","name":"A","density":"huge","elevation":{"mode":"glow"}}');
      expect(r.spec!.density, isNull);
      expect(r.spec!.elevationMode, isNull);
      expect(r.warnings.length, 2);
    });

    test('ไม่มีฟิลด์ที่รับ path/URL: ข้อความที่ดูเหมือน path ในช่องสีถูกปฏิเสธ', () {
      final r = parseNslt('{"schema":1,"id":"a","name":"A","light":{"colors":{"bg":"file:///etc/passwd","text":"http://x"}}}');
      expect(r.spec!.light.colors, isEmpty);
    });

    test('name ว่าง/ยาวเกิน → ใช้ id / ตัด พร้อมคำเตือน', () {
      expect(parseNslt('{"schema":1,"id":"abc","name":""}').spec!.name, 'abc');
      final long = parseNslt('{"schema":1,"id":"a","name":"${'n' * 500}"}');
      expect(long.spec!.name.length, 80);
      expect(long.warnings, isNotEmpty);
    });

    test('extends ที่ไม่ใช่ id ที่ถูกต้องถูกข้าม', () {
      final r = parseNslt('{"schema":1,"id":"a","name":"A","extends":"../x"}');
      expect(r.spec!.extendsId, isNull);
      expect(r.warnings, isNotEmpty);
    });
  });

  group('fuzz: ต้องไม่โยน exception ไม่ว่าอินพุตเสียแบบไหน', () {
    test('กลายพันธุ์ไฟล์ตัวอย่างแบบสุ่ม 3,000 ครั้ง', () {
      final rnd = Random(20261115);
      const alphabet = '{}[]":,.-0123456789eE+ truefalsnl#ABCDEF\\/\u0000ก';
      for (var i = 0; i < 3000; i++) {
        final chars = _sample.split('');
        final edits = 1 + rnd.nextInt(8);
        for (var e = 0; e < edits; e++) {
          final p = rnd.nextInt(chars.length);
          switch (rnd.nextInt(3)) {
            case 0:
              chars[p] = alphabet[rnd.nextInt(alphabet.length)];
            case 1:
              chars.removeAt(p);
            default:
              chars.insert(p, alphabet[rnd.nextInt(alphabet.length)]);
          }
          if (chars.isEmpty) break;
        }
        final text = chars.join();
        expect(() => parseNslt(text), returnsNormally, reason: text);
        // ถ้าอ่านผ่าน ต้อง resolve + เขียนกลับได้โดยไม่โยน (ยกเว้น NslResolveException ที่เป็นผลลัพธ์ที่คาดไว้)
        final r = parseNslt(text);
        if (r.ok) {
          expect(() => serializeNslt(r.spec!), returnsNormally, reason: text);
          for (final b in Brightness.values) {
            try {
              resolveTokens(r.spec!, b, lookup: builtinThemeById);
            } on NslResolveException {
              // ธีมที่ขาด root/ฐาน — ยอมรับได้
            }
          }
        }
      }
    });

    test('JSON ชนิดผิดตำแหน่ง (ค่าแทน object ฯลฯ) ไม่โยน', () {
      const cases = [
        '{"schema":1,"id":"a","name":5}',
        '{"schema":1,"id":"a","name":"A","light":5}',
        '{"schema":1,"id":"a","name":"A","light":{"colors":[1,2]}}',
        '{"schema":1,"id":"a","name":"A","light":{"extensions":{"nebular":5}}}',
        '{"schema":1,"id":"a","name":"A","shape":5}',
        '{"schema":1,"id":"a","name":"A","shape":{"radius":5}}',
        '{"schema":1,"id":"a","name":"A","type":"x"}',
        '{"schema":1,"id":"a","name":"A","elevation":[]}',
        '{"schema":1,"id":"a","name":"A","density":{}}',
      ];
      for (final c in cases) {
        expect(() => parseNslt(c), returnsNormally, reason: c);
        expect(parseNslt(c).ok || parseNslt(c).errors.isNotEmpty, isTrue, reason: c);
      }
    });

    test('อินพุตซ้อนลึกมากไม่ทำให้ล้ม', () {
      final deep = '[' * 5000 + ']' * 5000;
      expect(() => parseNslt(deep), returnsNormally);
      expect(parseNslt(deep).ok, isFalse);
    });
  });
}
