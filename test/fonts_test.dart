// ฟอนต์สองสคริปต์ (ละติน + ไทย) — ตัวตรวจไฟล์ฟอนต์, การจัดลำดับ, คีย์ในไฟล์ธีม (core 1.2)
import 'dart:math';
import 'dart:typed_data';

import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

/// ฟอนต์จำลองขั้นต่ำ : ตาราง cmap (format 12 หรือ 4) + name ; [ranges] คือช่วง codepoint ที่ "มีอักษร"
Uint8List fakeFont({required List<(int, int)> ranges, String name = 'Fake Sans', bool format4 = false}) {
  final cmap = BytesBuilder();
  void u16(BytesBuilder b, int v) => b.add([(v >> 8) & 255, v & 255]);
  void u32(BytesBuilder b, int v) => b.add([(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]);
  // header: version 0, 1 record (platform 3, encoding 1 or 10, offset 12)
  u16(cmap, 0);
  u16(cmap, 1);
  u16(cmap, 3);
  u16(cmap, format4 ? 1 : 10);
  u32(cmap, 12);
  if (format4) {
    final segs = [...ranges, (0xFFFF, 0xFFFF)];
    final n = segs.length;
    u16(cmap, 4);
    u16(cmap, 16 + n * 8);
    u16(cmap, 0);
    u16(cmap, n * 2);
    u16(cmap, 0);
    u16(cmap, 0);
    u16(cmap, 0);
    for (final s in segs) {
      u16(cmap, s.$2);
    }
    u16(cmap, 0);
    for (final s in segs) {
      u16(cmap, s.$1);
    }
    for (var i = 0; i < n; i++) {
      u16(cmap, 1); // idDelta: glyph = cp + 1 (never 0 inside a range)
    }
    for (var i = 0; i < n; i++) {
      u16(cmap, 0);
    }
  } else {
    u16(cmap, 12);
    u16(cmap, 0);
    u32(cmap, 16 + ranges.length * 12);
    u32(cmap, 0);
    u32(cmap, ranges.length);
    var g = 1;
    for (final r in ranges) {
      u32(cmap, r.$1);
      u32(cmap, r.$2);
      u32(cmap, g);
      g += r.$2 - r.$1 + 1;
    }
  }
  final nm = BytesBuilder();
  final utf16 = <int>[for (final c in name.codeUnits) ...[c >> 8, c & 255]];
  u16(nm, 0);
  u16(nm, 1);
  u16(nm, 6 + 12);
  u16(nm, 3);
  u16(nm, 1);
  u16(nm, 0x409);
  u16(nm, 1);
  u16(nm, utf16.length);
  u16(nm, 0);
  nm.add(utf16);

  final tables = [(0x636D6170, cmap.toBytes()), (0x6E616D65, nm.toBytes())]; // cmap, name
  final out = BytesBuilder();
  u32(out, 0x00010000);
  u16(out, tables.length);
  u16(out, 0);
  u16(out, 0);
  u16(out, 0);
  var off = 12 + tables.length * 16;
  for (final t in tables) {
    u32(out, t.$1);
    u32(out, 0);
    u32(out, off);
    u32(out, t.$2.length);
    off += t.$2.length;
  }
  for (final t in tables) {
    out.add(t.$2);
  }
  return out.toBytes();
}

const _latin = [(0x20, 0x7E)];
const _thai = [(0x0E01, 0x0E5B)];

NslFontInfo _info(Uint8List b) {
  final r = inspectFontBytes(b);
  expect(r.isOk, isTrue, reason: r.error);
  return r.info!;
}

void main() {
  group('inspectFontBytes', () {
    test('Latin-only font (cmap format 12)', () {
      final i = _info(fakeFont(ranges: _latin, name: 'My Latin'));
      expect(i.coversLatin, isTrue);
      expect(i.coversThai, isFalse);
      expect(i.familyName, 'My Latin');
    });

    test('Thai + Latin font (cmap format 12)', () {
      final i = _info(fakeFont(ranges: [..._latin, ..._thai]));
      expect(i.coversLatin && i.coversThai, isTrue);
    });

    test('cmap format 4 is read the same way', () {
      final a = _info(fakeFont(ranges: _latin, format4: true));
      expect(a.coversLatin, isTrue);
      expect(a.coversThai, isFalse);
      final b = _info(fakeFont(ranges: [..._latin, ..._thai], format4: true));
      expect(b.coversThai, isTrue);
    });

    test('a font with only a few Thai letters does not count as Thai', () {
      final i = _info(fakeFont(ranges: [..._latin, (0x0E01, 0x0E05)]));
      expect(i.coversThai, isFalse);
    });

    test('family name loses control characters and path separators', () {
      final i = _info(fakeFont(ranges: _latin, name: 'A/B:C\\D'));
      expect(i.familyName, 'ABCD');
    });

    test('rejects what is not a usable font', () {
      expect(inspectFontBytes(Uint8List(0)).isOk, isFalse);
      expect(inspectFontBytes(Uint8List.fromList(List.filled(100, 65))).isOk, isFalse);
      Uint8List withTag(int t) {
        final b = fakeFont(ranges: _latin);
        b.buffer.asByteData().setUint32(0, t);
        return b;
      }

      expect(inspectFontBytes(withTag(0x74746366)).error, contains('.ttc'));
      expect(inspectFontBytes(withTag(0x774F4646)).error, contains('WOFF'));
      expect(inspectFontBytes(withTag(0x774F4632)).error, contains('WOFF'));
    });

    test('rejects a table that points outside the file', () {
      final b = fakeFont(ranges: _latin);
      b.buffer.asByteData().setUint32(12 + 12, 0x7FFFFFFF); // length of the first table
      expect(inspectFontBytes(b).isOk, isFalse);
    });

    test('rejects a truncated file', () {
      final b = fakeFont(ranges: _latin);
      expect(inspectFontBytes(Uint8List.sublistView(b, 0, 20)).isOk, isFalse);
      expect(inspectFontBytes(Uint8List.sublistView(b, 0, b.length - 5)).isOk, isFalse);
    });

    test('rejects a file over the size limit', () {
      expect(inspectFontBytes(Uint8List(kMaxFontBytes + 1)).error, contains('too large'));
    });

    test('fuzz: mutated fonts never throw', () {
      final rnd = Random(7);
      final seeds = [
        fakeFont(ranges: [..._latin, ..._thai]),
        fakeFont(ranges: [..._latin, ..._thai], format4: true),
      ];
      for (var i = 0; i < 4000; i++) {
        final b = Uint8List.fromList(seeds[i % 2]);
        for (var k = 0; k < 1 + rnd.nextInt(6); k++) {
          b[rnd.nextInt(b.length)] = rnd.nextInt(256);
        }
        final cut = rnd.nextInt(4) == 0 ? Uint8List.sublistView(b, 0, rnd.nextInt(b.length)) : b;
        inspectFontBytes(cut); // must not throw
      }
    });
  });

  group('planFontOrder', () {
    final latinOnly = NslFontInfo(familyName: 'L', coversThai: false, coversLatin: true);
    final thaiOnly = NslFontInfo(familyName: 'T', coversThai: true, coversLatin: false);
    final both = NslFontInfo(familyName: 'B', coversThai: true, coversLatin: true);

    test('Latin font without Thai + Thai font: as chosen, no issues', () {
      final p = planFontOrder(latin: latinOnly, thai: thaiOnly);
      expect(p.thaiFirst, isFalse);
      expect(p.issues, isEmpty);
    });

    test('Latin font with Thai + Thai font without Latin: Thai font goes first', () {
      final p = planFontOrder(latin: both, thai: thaiOnly);
      expect(p.thaiFirst, isTrue);
      expect(p.issues, isEmpty);
    });

    test('both fonts cover both scripts: cannot be forced, user is told', () {
      final p = planFontOrder(latin: both, thai: both);
      expect(p.thaiFirst, isFalse);
      expect(p.issues, [NslFontIssue.bothCoverBoth]);
    });

    test('a Thai slot without Thai letters is reported', () {
      final p = planFontOrder(latin: latinOnly, thai: latinOnly);
      expect(p.issues, contains(NslFontIssue.thaiFontLacksThai));
    });

    test('a Latin slot without Latin letters is reported', () {
      final p = planFontOrder(latin: thaiOnly, thai: thaiOnly);
      expect(p.issues, contains(NslFontIssue.latinFontLacksLatin));
    });

    test('unknown fonts (null) decide nothing', () {
      expect(planFontOrder().issues, isEmpty);
      expect(planFontOrder(latin: both).thaiFirst, isFalse);
      expect(planFontOrder(thai: thaiOnly).issues, isEmpty);
    });
  });

  group('NslType two-script fonts', () {
    test('without Thai slots nothing changes (legacy themes)', () {
      const t = NslType(family: 'Inter');
      expect(t.effectiveFamily, 'Inter');
      expect(t.fallback.first, kNslFontFallback.first);
      expect(t.fallback, isNot(contains('Inter')));
      expect(const NslType().effectiveFamily, kNslThaiFont);
    });

    test('Thai slot comes right after the Latin font, then the built-in fallbacks', () {
      const t = NslType(family: 'Inter', familyThai: 'Sarabun');
      expect(t.effectiveFamily, 'Inter');
      expect(t.fallback.first, 'Sarabun');
      expect(t.fallback.last, kNslFontFallback.last);
    });

    test('thaiFirst swaps them', () {
      const t = NslType(family: 'Inter', familyThai: 'Sarabun', thaiFirst: {'family'});
      expect(t.effectiveFamily, 'Sarabun');
      expect(t.fallback.first, 'Inter');
    });

    test('only a Thai slot: Thai font first, Noto behind it for letters it lacks', () {
      const t = NslType(familyThai: 'Sarabun');
      expect(t.effectiveFamily, 'Sarabun');
      expect(t.fallback.first, kNslThaiFont);
    });

    test('content role follows its own slots and falls back to the UI font', () {
      expect(const NslType(family: 'Inter').effectiveContent, 'Inter');
      expect(const NslType(family: 'Inter', content: 'Lora', contentThai: 'Mali').contentFallback.first, 'Mali');
      expect(const NslType(family: 'Inter', familyThai: 'Sarabun').contentFallback, const NslType(family: 'Inter', familyThai: 'Sarabun').fallback);
    });

    test('equality and copyWith include the new fields', () {
      const a = NslType(family: 'Inter', familyThai: 'Sarabun');
      expect(a, const NslType(family: 'Inter', familyThai: 'Sarabun'));
      expect(a == const NslType(family: 'Inter', familyThai: 'Prompt'), isFalse);
      expect(a == a.copyWith(thaiFirst: {'family'}), isFalse);
      expect(a.copyWith(monoThai: 'Mali').monoThai, 'Mali');
    });

    test('the fallback chain has no duplicates', () {
      const t = NslType(family: 'Inter', familyThai: 'Tahoma');
      expect(t.fallback.toSet().length, t.fallback.length);
    });

    test('component text styles carry the chain', () {
      const t = NslType(family: 'Inter', familyThai: 'Sarabun');
      final s = TextStyle(fontFamily: t.effectiveFamily, fontFamilyFallback: t.fallback);
      expect(s.fontFamilyFallback!.first, 'Sarabun');
    });
  });

  group('theme file keys', () {
    String theme(String type) => '{"schema":1,"id":"t","name":"t","extends":"nsl.nebular","type":$type}';

    test('familyThai/contentThai/monoThai round trip', () {
      final r = parseNslt(theme('{"family":"Inter","familyThai":"Sarabun","contentThai":"Mali","monoThai":"Noto Sans Mono"}'));
      final s = r.spec!;
      expect((s.family, s.familyThai, s.contentThai, s.monoThai), ('Inter', 'Sarabun', 'Mali', 'Noto Sans Mono'));
      final again = parseNslt(serializeNslt(s)).spec!;
      expect((again.familyThai, again.contentThai, again.monoThai), ('Sarabun', 'Mali', 'Noto Sans Mono'));
    });

    test('a theme without Thai keys serializes without them', () {
      final s = parseNslt(theme('{"family":"Inter"}')).spec!;
      expect(serializeNslt(s), isNot(contains('Thai')));
    });

    test('bad Thai font names are dropped with a warning', () {
      final r = parseNslt(theme('{"familyThai":"../evil","contentThai":"","monoThai":5}'));
      final s = r.spec!;
      expect((s.familyThai, s.contentThai, s.monoThai), (null, null, null));
      expect(r.warnings.where((w) => w.contains('Thai')).length, 3);
    });

    test('a child theme inherits and overrides the Thai slots', () {
      final base = parseNslt('{"schema":1,"id":"base","name":"b","extends":"nsl.nebular","type":{"familyThai":"Sarabun","contentThai":"Mali"}}').spec!;
      final child = parseNslt('{"schema":1,"id":"child","name":"c","extends":"base","type":{"familyThai":"Prompt"}}').spec!;
      NslThemeSpec? lookup(String id) => id == 'base' ? base : builtinThemeById(id);
      final t = resolveTokens(child, Brightness.light, lookup: lookup).type;
      expect(t.familyThai, 'Prompt');
      expect(t.contentThai, 'Mali');
    });

    test('the schema lists the Thai roles', () {
      final type = buildTokensSchema()['type'] as Map;
      expect(type['thaiRoles'], ['familyThai', 'contentThai', 'monoThai']);
    });
  });
}
