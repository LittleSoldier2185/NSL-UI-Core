// เฟส 8: core v1.0 — token ใหม่, ค่า lite (accent/โหมด), ฟอนต์สามบทบาท, ที่เก็บแบบ interface, ส่งออก ARGB, density, schema
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart' show ThemeMode, VisualDensity;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

NslTokens _res(NslThemeSpec s, Brightness b, {NslThemeLookup? lookup}) =>
    resolveTokens(s, b, lookup: lookup ?? builtinThemeById);

NslThemeSpec _child({String id = 'kid', NslAppearance? a, Color? accent}) => NslThemeSpec(
      id: id,
      name: id,
      extendsId: kBuiltinDevId,
      light: NslModeSpec(colors: {'accent': ?accent}),
      dark: NslModeSpec(colors: {'accent': ?accent}),
    ).withAppearance(a);

void main() {
  group('token ใหม่ใน core v1.0', () {
    test('selected / accentBorder / textFaint มีค่าและคำนวณจาก root ได้ ทั้งสองโหมด', () {
      for (final b in Brightness.values) {
        final t = _res(kBuiltinDev, b);
        expect(t.colors.selected, isNot(t.colors.surface));
        expect(t.colors.accentBorder, isNot(t.colors.surface));
        expect(t.colors.textFaint, isNot(t.colors.text));
        // faint จางกว่า muted (ใกล้พื้นกว่า)
        expect(contrastRatio(t.colors.textFaint, t.colors.surface), lessThan(contrastRatio(t.colors.textMuted, t.colors.surface)));
      }
    });

    test('ระบุค่าเองในธีมได้และไม่ถูกแตะ ; เปลี่ยน accent โดยไม่ระบุ → accentBorder คำนวณใหม่ แต่ selected คงเดิม', () {
      final base = NslThemeSpec(
        id: 'b',
        name: 'b',
        extendsId: kBuiltinDevId,
        light: const NslModeSpec(colors: {'selected': Color(0xFFE2D6BF), 'accentBorder': Color(0xFFD9A593)}),
      );
      final t0 = _res(base, Brightness.light);
      expect(t0.colors.selected, const Color(0xFFE2D6BF));
      expect(t0.colors.accentBorder, const Color(0xFFD9A593));
      final kid = NslThemeSpec(
        id: 'k',
        name: 'k',
        extendsId: 'b',
        light: const NslModeSpec(colors: {'accent': Color(0xFF1D4ED8)}),
      );
      final t1 = _res(kid, Brightness.light, lookup: (id) => id == 'b' ? base : builtinThemeById(id));
      expect(t1.colors.selected, const Color(0xFFE2D6BF));
      expect(t1.colors.accentBorder, isNot(const Color(0xFFD9A593)));
    });

    test('จำนวน token สี core = 30 และไม่ซ้ำ (parity เทสต์ชุดเดิมคุมค่าเดิมของ Dev/Resonance อยู่)', () {
      expect(kCoreColorKeys.length, 30);
      expect(kCoreColorKeys.toSet().length, 30);
    });
  });

  group('ค่า lite: accent + โหมด', () {
    test('preset ชนะ accent ในธีม และใช้ค่าเดิมของ preset ตรง ๆ (ไม่คำนวณ)', () {
      final p = accentPresetById('blue')!;
      final spec = _child(a: const NslAppearance(presetId: 'blue'), accent: const Color(0xFFFF00FF));
      final l = _res(spec, Brightness.light), d = _res(spec, Brightness.dark);
      expect(l.colors.accent, p.light.$1);
      expect(l.colors.accentTint, p.light.$2);
      expect(l.colors.accentInk, p.light.$3);
      expect(d.colors.accent, p.dark.$1);
      expect(d.colors.accentTint, p.dark.$2);
      expect(d.colors.accentInk, p.dark.$3);
      expect(l.colors.onAccent, onAccentFor(p.light.$1));
    });

    test('สีกำหนดเองผ่าน accentTints (HSL) และตัวอักษรบน accent/พื้นอ่อนอ่านได้ทั้งสองโหมด', () {
      for (final c in const [Color(0xFF7B58D6), Color(0xFFF4B860), Color(0xFF00FF00), Color(0xFFFFFFFF), Color(0xFF000000)]) {
        final spec = _child(a: NslAppearance(customAccent: c));
        for (final b in Brightness.values) {
          final t = _res(spec, b);
          final set = accentTints(c, b == Brightness.dark);
          expect(t.colors.accent, set.$1);
          expect(contrastRatio(t.colors.onAccent, t.colors.accent), greaterThanOrEqualTo(4.5));
          expect(contrastRatio(t.colors.accentInk, t.colors.accentTint), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('ไม่ตั้ง accent = ใช้ของธีมเดิมทุกบิต ; ล้างด้วย clearedAccent ; preset ที่ไม่รู้จักถูกข้าม', () {
      final plain = _child(accent: const Color(0xFF123456));
      final withDefault = plain.withAppearance(const NslAppearance(mode: NslModeChoice.dark));
      expect(_res(withDefault, Brightness.light), _res(plain, Brightness.light));
      const a = NslAppearance(presetId: 'blue');
      expect(a.clearedAccent().hasAccent, isFalse);
      final ghost = plain.withAppearance(const NslAppearance(presetId: 'nope'));
      expect(_res(ghost, Brightness.light).colors.accent, const Color(0xFF123456));
    });

    test('JSON: ไป-กลับเท่าเดิม ; ค่าเสีย/ชนิดผิด/สีผิดรูปแบบ = ข้ามโดยไม่โยน', () {
      const a = NslAppearance(mode: NslModeChoice.dark, customAccent: Color(0xFF7B58D6));
      expect(NslAppearance.fromJson(a.toJson()), a);
      const b = NslAppearance(presetId: 'teal');
      expect(NslAppearance.fromJson(b.toJson()), b);
      final bads = <Object?>[
        null,
        5,
        'x',
        <Object?>[],
        {'mode': 7, 'preset': 3, 'customAccent': '#12'},
        {'preset': '../x'},
        {'customAccent': '#GGGGGG'},
      ];
      for (final bad in bads) {
        expect(NslAppearance.fromJson(bad).hasAccent, isFalse, reason: '$bad');
      }
      expect(NslAppearance.fromJson({'mode': 'dark'}).mode.themeMode, ThemeMode.dark);
    });

    test('ค่า lite ไม่ถูกเขียนลงไฟล์ธีม', () {
      final spec = _child(a: const NslAppearance(presetId: 'red'));
      expect(serializeNslt(spec).contains('red'), isFalse);
      expect(serializeNslt(spec).contains('appearance'), isFalse);
    });
  });

  group('ค่า lite เก็บ/โหลดผ่านตัวควบคุม', () {
    test('setAppearance เก็บลง settings และโหลดใหม่ได้ ; effective: ธีมในตัว < ไฟล์ธีม < lite ; safe mode ล้างทั้งหมด', () async {
      final st = NslMemoryThemeStorage();
      final c = NslThemeController(st);
      await c.reload();
      expect(c.themeMode, ThemeMode.system);
      await c.setAppearance(const NslAppearance(mode: NslModeChoice.dark, presetId: 'green'));
      final c2 = NslThemeController(st);
      await c2.reload();
      expect(c2.appearance.presetId, 'green');
      expect(c2.themeMode, ThemeMode.dark);

      final green = accentPresetById('green')!;
      // ไม่มีธีมผู้ใช้ → fallback ที่ทับด้วย lite
      expect(_res(c2.effective(kBuiltinDev), Brightness.light).colors.accent, green.light.$1);
      // มีธีมผู้ใช้ที่ตั้ง accent → lite ยังชนะ
      await st.saveTheme(_child(id: 'mine', accent: const Color(0xFF123456)));
      await c2.reload();
      await c2.select('mine');
      final eff = c2.effective(kBuiltinDev);
      expect(eff.id, 'mine');
      expect(_res(eff, Brightness.light, lookup: c2.lookup).colors.accent, green.light.$1);
      // เอา lite ออก → accent ของไฟล์ธีม
      await c2.setAppearance(c2.appearance.clearedAccent());
      expect(_res(c2.effective(kBuiltinDev), Brightness.light, lookup: c2.lookup).colors.accent, const Color(0xFF123456));
      // safe mode: ได้ fallback ล้วน ๆ
      await c2.setAppearance(const NslAppearance(presetId: 'green'));
      await c2.setSafeMode(true);
      expect(identical(c2.effective(kBuiltinDev), kBuiltinDev), isTrue);
    });

    test('ui-settings: ไฟล์ค่าเสียอ่านแล้วได้ค่าเริ่มต้น ไม่โยน', () {
      for (final bad in ['', '{', '[]', '{"appearance":5}', '{"appearance":{"mode":{}}}', '{"safeMode":1}']) {
        final s = NslUiSettings.parse(bad);
        expect(s.appearance.hasAccent, isFalse, reason: bad);
      }
    });
  });

  group('นำเข้า/ส่งออกไฟล์ธีม (Android และทุกแพลตฟอร์ม)', () {
    test('นำเข้าสำเร็จ → ใช้ได้ ; ส่งออกแล้วนำเข้าอีกเครื่องได้เท่าเดิม', () async {
      final c = NslThemeController(NslMemoryThemeStorage());
      final src = serializeNslt(const NslThemeSpec(
        id: 'sea',
        name: 'Sea',
        core: kNslCoreVersion,
        extendsId: kBuiltinDevId,
        light: NslModeSpec(colors: {'accent': Color(0xFF0369A1)}),
      ));
      final r = await c.importThemeText(src);
      expect(r.ok, isTrue);
      expect(r.id, 'sea');
      expect(c.userThemes.map((e) => e.id), ['sea']);
      final out = c.exportThemeText('sea')!;
      final c2 = NslThemeController(NslMemoryThemeStorage());
      expect((await c2.importThemeText(out)).ok, isTrue);
      expect(c2.exportThemeText('sea'), out);
    });

    test('ไฟล์เสีย / id สงวน (รวม nsl.nebular) / schema ใหม่เกิน / ใหญ่เกิน → ปฏิเสธพร้อมเหตุผล ไม่โยน ไม่เขียนอะไร', () async {
      final st = NslMemoryThemeStorage();
      final c = NslThemeController(st);
      final bads = [
        '',
        'not json',
        '{"schema":1,"id":"nsl.nebular","name":"x"}',
        '{"schema":99,"id":"a","name":"a"}',
        List.filled(kNsltMaxBytes + 1, 'x').join(),
      ];
      for (final bad in bads) {
        final r = await c.importThemeText(bad);
        expect(r.ok, isFalse, reason: bad.length > 40 ? 'big' : bad);
        expect(r.errors, isNotEmpty);
      }
      expect((await st.loadAll()).themes, isEmpty);
    });
  });

  group('ฟอนต์สามบทบาท + ขนาดขั้นต่ำ + เวอร์ชัน core ในไฟล์', () {
    test('type.content / minSize / core: อ่าน-เขียนไป-กลับ, clamp, ค่าผิดถูกข้าม', () {
      const src =
          '{"schema":1,"core":"1.0","id":"w","name":"W","extends":"nsl.nebular","type":{"family":"IBM Plex Sans Thai","content":"Noto Serif Thai","mono":"IBM Plex Mono","minSize":13,"scale":1.1}}';
      final s = parseNslt(src).spec!;
      expect(s.core, '1.0');
      expect(s.content, 'Noto Serif Thai');
      expect(s.minSize, 13);
      expect(parseNslt(serializeNslt(s)).spec!.content, 'Noto Serif Thai');
      expect(serializeNslt(s), contains('"core": "1.0"'));
      final t = _res(s, Brightness.light, lookup: (_) => kBuiltinDev).type;
      expect(t.effectiveContent, 'Noto Serif Thai');
      expect(t.fit(10), 13); // 10×1.1 = 11 < 13 → ยกขึ้นขั้นต่ำ
      expect(t.fit(14), closeTo(15.4, 1e-9));
      expect(const NslType().effectiveContent, kNslThaiFont); // ไม่ระบุ = ใช้ฟอนต์ UI
      final bad = parseNslt('{"schema":1,"id":"w","name":"W","core":"x","type":{"minSize":999,"content":"a/b"}}');
      expect(bad.spec!.core, isNull);
      expect(bad.spec!.minSize, NslType.maxMinSize);
      expect(bad.spec!.content, isNull);
    });

    test('ไฟล์จาก core ใหม่กว่า: เตือน แต่อ่านได้ และคีย์ที่ไม่รู้จักถูกเก็บกลับตอนบันทึก (รุ่นเก่าไม่ทำของรุ่นใหม่หาย)', () {
      final r = parseNslt(
          '{"schema":1,"core":"1.7","id":"n","name":"N","futureThing":{"a":1},"light":{"colors":{"accent":"#112233","brandNew":"#445566"}}}');
      expect(r.ok, isTrue);
      expect(r.warnings.any((w) => w.contains('newer core')), isTrue);
      final out = serializeNslt(r.spec!);
      expect(out, contains('futureThing'));
      expect(out, contains('"core": "1.7"'));
    });
  });

  group('ชุดสี categorical', () {
    test('8 สีต่างกัน ทั้งสองโหมด และ tintFor ของแต่ละสีอ่านได้', () {
      for (final b in Brightness.values) {
        final t = _res(kBuiltinDev, b);
        expect(t.categorical.length, 8);
        expect(t.categorical.toSet().length, 8);
        for (final c in t.categorical) {
          final tt = tintFor(c, t.isDark);
          expect(contrastRatio(tt.$2, tt.$1), greaterThanOrEqualTo(4.5));
        }
      }
    });
  });

  group('ส่งออก ARGB สำหรับ native', () {
    test('มีสี core ครบและสีส่วนขยายเป็น <ext>.<key> ค่าตรงกับ token', () {
      final t = _res(kBuiltinDev, Brightness.dark);
      final m = t.toArgbMap();
      for (final k in kCoreColorKeys) {
        expect(m[k], t.colors[k].toARGB32(), reason: k);
      }
      expect(m['nebular.canvas'], t.ext('nebular', 'canvas')!.toARGB32());
      expect(m['spectrum.panelBottom'], isNotNull);
      expect(m.values.every((v) => v >= 0 && v <= 0xFFFFFFFF), isTrue);
    });
  });

  group('density บนจอสัมผัส', () {
    test('compact → normal เมื่อ touch ; แบบเดิมไม่เปลี่ยน', () {
      final colors = _res(kBuiltinDev, Brightness.light).colors;
      final compact = NslTokens(brightness: Brightness.light, colors: colors, density: NslDensity.compact);
      expect(compact.visualDensity, const VisualDensity(horizontal: -2, vertical: -2));
      expect(compact.visualDensityFor(touch: true), VisualDensity.standard);
      expect(compact.visualDensityFor(), compact.visualDensity);
      final comfy = NslTokens(brightness: Brightness.light, colors: colors, density: NslDensity.comfortable);
      expect(comfy.visualDensityFor(touch: true), comfy.visualDensity);
      expect(kMinTapTarget, 44);
    });
  });

  group('tokens.schema.json', () {
    final file = File('schema/tokens.schema.json');

    test('ไฟล์ที่เช็กอินตรงกับที่โค้ดสร้าง (แก้ token แล้วรัน NSL_UPDATE_SCHEMA=1 flutter test test/phase8_test.dart)', () {
      final want = tokensSchemaJson();
      if (Platform.environment['NSL_UPDATE_SCHEMA'] == '1') {
        file.createSync(recursive: true);
        file.writeAsStringSync(want);
      }
      expect(file.existsSync(), isTrue, reason: 'ยังไม่มี schema/tokens.schema.json');
      expect(file.readAsStringSync().replaceAll('\r\n', '\n'), want);
    });

    test('ครอบคลุม token ทั้งหมด: ทุกสี core, ทุกส่วนขยาย, preset, ธีมในตัว และไม่มี id ซ้ำ', () {
      final s = buildTokensSchema();
      final colors = (s['colors'] as List).cast<Map<String, Object?>>();
      expect(colors.map((c) => c['key']).toList(), kCoreColorKeys);
      expect(colors.where((c) => c['root'] == true).map((c) => c['key']).toSet(), kRootColorKeys.toSet());
      expect((s['extensions'] as List).length, kKnownExtensions.length);
      expect((s['appearance'] as Map)['presets'], hasLength(kAccentPresets.length));
      expect((s['builtinThemes'] as List).map((e) => (e as Map)['id']), kBuiltinThemeIds);
      expect(s['core'], kNslCoreVersion);
      expect(kAccentPresets.map((p) => p.id).toSet().length, kAccentPresets.length);
    });
  });
}
