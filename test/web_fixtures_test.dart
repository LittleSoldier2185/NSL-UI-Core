// สร้าง/ตรวจ fixture กลางที่เว็บ NSL Palette (TypeScript) ใช้พิสูจน์ว่า port ตรงกับ Dart
//
// - ฝั่งนี้ (Dart) คือแหล่งความจริง : เทสต์นี้คำนวณคำตอบจาก nsl_ui จริง แล้วเทียบกับไฟล์ที่เช็กอินไว้ใน web/
// - ถ้าแก้ core แล้วเทสต์นี้ล้ม : รัน `NSL_UPDATE_FIXTURES=1 flutter test test/web_fixtures_test.dart` แล้วรัน `npm test` ใน web/
//   (ถ้า TS ไม่ตรง เทสต์ฝั่งเว็บจะล้มและบอกว่าต้อง port อะไร)
// - ค่าสีทั้งหมดเทียบที่ระดับ 8 บิตต่อช่อง (ARGB32) เหมือนไฟล์ธีมจริง
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

final _update = Platform.environment['NSL_UPDATE_FIXTURES'] == '1';

// ---------------------------------------------------------------------------
// ธีมในตัว: เขียนเป็นข้อความ .nslt แล้วอ่านกลับ (ทั้งสองฝั่งเริ่มจากข้อความเดียวกัน จึงไม่มีเศษทศนิยมต่าง)

final Map<String, String> _builtinTexts = {for (final id in kBuiltinThemeIds) id: serializeNslt(builtinThemeById(id)!)};
NslThemeSpec? _builtin(String id) {
  final t = _builtinTexts[id];
  return t == null ? null : parseNslt(t).spec;
}

const _userTexts = <String, String>{
  'user.sea': '{"schema":1,"id":"user.sea","name":"Sea","extends":"nsl.nebular","light":{"colors":{"accent":"#0369A1"}},"dark":{"colors":{"accent":"#38BDF8"}}}',
  'user.sea2': '{"schema":1,"id":"user.sea2","name":"Sea 2","extends":"user.sea","dark":{"extensions":{"nebular":{"tableHead":"#334455"}}}}',
  'user.paper2': '{"schema":1,"core":"1.1","id":"user.paper2","name":"Paper 2","extends":"nsl.lyra.paper","light":{"colors":{"accent":"#1D4ED8"}}}',
  'user.pinned':
      '{"schema":1,"id":"user.pinned","name":"Pinned","extends":"nsl.lyra.paper","light":{"colors":{"accent":"#C0392B"},"extensions":{"lyra":{"accentDark":"#123456","typePlace":"#112233"}}}}',
  'user.full':
      '{"schema":1,"id":"user.full","name":"Full","extends":"nsl.default","shape":{"radius":{"md":10,"pill":500}},"type":{"family":"Sarabun","content":"Noto Serif Thai","mono":"Fira Code","scale":1.1,"minSize":12},"density":"compact","elevation":{"mode":"flat","strength":0.5},"light":{"colors":{"bg":"#101010"}}}',
  'user.standalone':
      '{"schema":1,"id":"user.standalone","name":"Standalone","light":{"colors":{"bg":"#F0F0F0","surface":"#FFFFFF","text":"#111111","accent":"#2255CC"}},"dark":{"colors":{"bg":"#0A0A0A","surface":"#181818","text":"#EEEEEE","accent":"#88AAFF"}}}',
  // สีโปร่งใส (#RRGGBBAA): พื้นป้ายสถานะและเส้นขอบเป็นขาว/สีโปร่ง ต้องวัด contrast ตามที่ตาเห็นจริง (ผสมบนพื้น)
  'user.translucent':
      '{"schema":1,"id":"user.translucent","name":"Translucent","dark":{"colors":{"bg":"#071433","surface":"#0E1D45","text":"#FFFFFF","accent":"#FFC83D","border":"#FFFFFF1F","successBg":"#4FE3B024","successText":"#7DF0C6","infoBg":"#6EC8FF24","infoText":"#9AD8FF","warnBg":"#FFC83D29","warnText":"#FFC83D","textMuted":"#FFFFFF80"}},"light":{"colors":{"bg":"#EEF2FA","surface":"#FFFFFF","text":"#0B1633","accent":"#FFC83D","dangerBg":"#B4231810","dangerText":"#B42318"}}}',
  'user.broken': '{"schema":1,"id":"user.broken","name":"Broken","extends":"user.gone"}',
  'user.cycle-a': '{"schema":1,"id":"user.cycle-a","name":"A","extends":"user.cycle-b"}',
  'user.cycle-b': '{"schema":1,"id":"user.cycle-b","name":"B","extends":"user.cycle-a"}',
  'user.noroot': '{"schema":1,"id":"user.noroot","name":"No root","light":{"colors":{"bg":"#FFFFFF"}}}',
  'user.d0': '{"schema":1,"id":"user.d0","name":"D0","extends":"nsl.default"}',
  'user.d1': '{"schema":1,"id":"user.d1","name":"D1","extends":"user.d0"}',
  'user.d2': '{"schema":1,"id":"user.d2","name":"D2","extends":"user.d1"}',
  'user.d3': '{"schema":1,"id":"user.d3","name":"D3","extends":"user.d2"}',
  'user.d4': '{"schema":1,"id":"user.d4","name":"D4","extends":"user.d3"}',
  'user.d5': '{"schema":1,"id":"user.d5","name":"D5","extends":"user.d4"}',
  'user.d6': '{"schema":1,"id":"user.d6","name":"D6","extends":"user.d5"}',
  'user.d7': '{"schema":1,"id":"user.d7","name":"D7","extends":"user.d6"}',
  'user.d8': '{"schema":1,"id":"user.d8","name":"D8","extends":"user.d7"}',
};

final Map<String, NslThemeSpec> _users = {for (final e in _userTexts.entries) e.key: parseNslt(e.value).spec!};
NslThemeSpec? _lookup(String id) => _users[id] ?? _builtin(id);

// ---------------------------------------------------------------------------

Map<String, Object?> _tokensJson(NslTokens t) => {
      'colors': {for (final k in kCoreColorKeys) k: t.colors[k].toARGB32()},
      'ext': {
        for (final e in t.extensions.entries) e.key: {for (final c in e.value.entries) c.key: c.value.toARGB32()},
      },
      'shape': t.shape.toMap(),
      'type': {
        if (t.type.family != null) 'family': t.type.family,
        if (t.type.content != null) 'content': t.type.content,
        if (t.type.mono != null) 'mono': t.type.mono,
        'scale': t.type.scale,
        if (t.type.minSize != null) 'minSize': t.type.minSize,
      },
      'density': t.density.name,
      'elevation': {'mode': t.elevation.mode.name, 'strength': t.elevation.strength},
    };

Map<String, Object?> _resolveCase(String label, NslThemeSpec spec, NslAppearance? a, Brightness b) {
  final s = a == null ? spec : spec.withAppearance(a);
  final out = <String, Object?>{
    'label': label,
    'spec': spec.id,
    if (a != null) 'appearance': a.toJson(),
    'brightness': b.name,
  };
  try {
    out['expected'] = _tokensJson(resolveTokens(s, b, lookup: _lookup));
  } on NslResolveException catch (e) {
    out['error'] = e.message;
  }
  return out;
}

class _Lcg {
  _Lcg(this.s);
  int s;
  int next() => s = (s * 1103515245 + 12345) & 0x7FFFFFFF;
  int below(int n) => next() % n;
}

String _norm(String m) => m.startsWith('not valid JSON') ? 'not valid JSON' : m;

Map<String, Object?> _parseCase(String source) {
  final r = parseNslt(source);
  return {
    'source': source,
    'ok': r.ok,
    'errors': [for (final e in r.errors) _norm(e)],
    'warnings': r.warnings,
    if (r.spec != null) 'serialized': serializeNslt(r.spec!),
  };
}

Map<String, Object?> _build() {
  // --- resolve
  final resolve = <Map<String, Object?>>[];
  final all = <String, NslThemeSpec>{for (final id in kBuiltinThemeIds) id: _builtin(id)!, ..._users};
  for (final e in all.entries) {
    for (final b in Brightness.values) {
      resolve.add(_resolveCase(e.key, e.value, null, b));
    }
  }
  const customs = [0xFF7B58D6, 0xFFF4B860, 0xFF00FF00, 0xFFFFFFFF, 0xFF000000, 0xFF14958B];
  final apps = <NslAppearance>[
    for (final p in kAccentPresets) NslAppearance(presetId: p.id),
    for (final c in customs) NslAppearance(customAccent: Color(c)),
  ];
  for (final base in ['nsl.nebular', 'nsl.lyra.paper', 'user.sea', 'nsl.spectrum']) {
    for (final a in apps) {
      for (final b in Brightness.values) {
        resolve.add(_resolveCase('lite:$base', all[base]!, a, b));
      }
    }
  }

  // --- tint
  const goldenBases = [0xFF7B58D6, 0xFFF4B860, 0xFF0F766E, 0xFFFFFFFF, 0xFF000000, 0xFF808080, 0xFFFF0000, 0xFF00FF00, 0xFF2459C9, 0xFFFFE082, 0xFF14958B, 0xFF42F8F7];
  final rnd = _Lcg(7);
  final bases = [...goldenBases, for (var i = 0; i < 400; i++) 0xFF000000 | (rnd.next() & 0xFFFFFF)];
  final tints = <Map<String, Object?>>[];
  for (final v in bases) {
    for (final dark in [false, true]) {
      final a = accentTints(Color(v), dark);
      final t = tintFor(Color(v), dark);
      tints.add({
        'base': v,
        'dark': dark,
        'accent': a.$1.toARGB32(),
        'soft': a.$2.toARGB32(),
        'ink': a.$3.toARGB32(),
        'bg': t.$1.toARGB32(),
        'fg': t.$2.toARGB32(),
      });
    }
  }

  // --- parse (ตัวอย่างเขียนมือ + สุ่มกลายพันธุ์)
  final hand = <String>[
    ..._userTexts.values,
    ..._builtinTexts.values,
    '',
    'not json',
    '[]',
    '5',
    '{}',
    '{"schema":0,"id":"a","name":"a"}',
    '{"schema":"1","id":"a","name":"a"}',
    '{"schema":2,"id":"a","name":"a"}',
    '{"schema":1,"id":"A","name":"a"}',
    '{"schema":1,"id":"a"}',
    '{"schema":1,"id":"a","name":"   "}',
    '{"schema":1,"id":"a","name":"${List.filled(100, 'x').join()}"}',
    '{"schema":1,"id":"a","name":"a","core":"9.9"}',
    '{"schema":1,"id":"a","name":"a","core":"x"}',
    '{"schema":1,"id":"a","name":"a","extends":"Bad Id"}',
    '{"schema":1,"id":"a","name":"a","light":5,"dark":[]}',
    '{"schema":1,"id":"a","name":"a","light":{"colors":{"bg":"#12345","accent":"#GGGGGG","text":5,"surface":"#112233"}}}',
    '{"schema":1,"id":"a","name":"a","light":{"colors":5,"extensions":{"x":5,"nebular":{"canvas":"#1","dot":"#112233AA"}}}}',
    '{"schema":1,"id":"a","name":"a","shape":{"radius":{"md":-5,"pill":5000,"zz":1,"xs":"a"}}}',
    '{"schema":1,"id":"a","name":"a","type":{"scale":3,"family":"a/b","mono":"   ","content":"ok","minSize":2}}',
    '{"schema":1,"id":"a","name":"a","type":{"scale":1e999,"minSize":"x"}}',
    '{"schema":1,"id":"a","name":"a","density":"tiny","elevation":{"mode":"glow","strength":9}}',
    '{"schema":1,"id":"a","name":"a","elevation":{"strength":-1},"future":{"a":[1,2,{"b":null}]},"zzz":1}',
    '{"schema":1,"id":"a","name":"ไทย","extends":"nsl.default","light":{"colors":{"accent":"#aabbcc"}}}',
    '{"schema":1,"id":"a","name":"a","light":{"colors":{"accent":"#AABBCC80"}}}',
    '[' * 5000,
  ];
  final bases2 = [..._userTexts.values.take(6), _builtinTexts[kBuiltinLyraPaperId]!];
  final r2 = _Lcg(99);
  const junk = ['{', '}', '[', ']', '"', ',', ':', '0', 'a', 'Z', '#', ' '];
  final fuzz = <String>[];
  for (var i = 0; i < 300; i++) {
    final base = bases2[r2.below(bases2.length)];
    switch (r2.below(4)) {
      case 0:
        fuzz.add(base.substring(0, r2.below(base.length)));
      case 1:
        final pos = r2.below(base.length);
        fuzz.add(base.substring(0, pos) + junk[r2.below(junk.length)] + base.substring(pos + 1));
      case 2:
        final j = jsonDecode(base);
        if (j is Map<String, Object?>) {
          const vals = <Object?>['#12345', '123456', 5, null, '#GGGGGG', '#12345678', '', true, <Object?>[], 'compact'];
          final keys = ['schema', 'id', 'name', 'extends', 'core', 'light', 'dark', 'shape', 'type', 'density', 'elevation'];
          j[keys[r2.below(keys.length)]] = vals[r2.below(vals.length)];
          fuzz.add(jsonEncode(j));
        }
      default:
        final j = jsonDecode(base);
        if (j is Map<String, Object?>) {
          j['extra${r2.below(9)}'] = {'k': r2.below(100)};
          final mode = j['light'];
          if (mode is Map<String, Object?>) {
            mode['colors'] = {...?(mode['colors'] as Map<String, Object?>?), 'novel': '#0A0B0C', 'bg': r2.below(2) == 0 ? '#ffffff' : 12};
          }
          fuzz.add(jsonEncode(j));
        }
    }
  }
  final parse = [for (final s in [...hand, ...fuzz]) _parseCase(s)];

  // --- contrast
  final contrast = <Map<String, Object?>>[];
  for (final e in all.entries) {
    for (final b in Brightness.values) {
      try {
        final t = resolveTokens(e.value, b, lookup: _lookup);
        contrast.add({
          'spec': e.key,
          'brightness': b.name,
          'checks': [for (final c in checkContrast(t)) {'name': c.name, 'ratio': c.ratio, 'passes': c.passes}],
          'unusable': isUnusable(t),
        });
      } on NslResolveException {
        // ธีมเสียไม่มีรายงาน
      }
    }
  }

  // --- autoFix
  const draftTexts = {
    'lowText': '{"schema":1,"id":"a","name":"a","extends":"nsl.nebular","light":{"colors":{"bg":"#FFFFFF","surface":"#FFFFFF","text":"#CCCCCC"}}}',
    'lightAccent': '{"schema":1,"id":"b","name":"b","extends":"nsl.nebular","light":{"colors":{"accent":"#FFEE00"}},"dark":{"colors":{"accent":"#FFEE00"}}}',
    'darkMismatch': '{"schema":1,"id":"c","name":"c","extends":"nsl.nebular","dark":{"colors":{"bg":"#101010","surface":"#202020","text":"#303030","accent":"#444444"}}}',
    'already': '{"schema":1,"id":"d","name":"d","extends":"nsl.nebular"}',
  };
  final autofix = <Map<String, Object?>>[];
  for (final e in draftTexts.entries) {
    final d = NslThemeDraft.fromSpec(parseNslt(e.value).spec!);
    final changed = d.autoFix(_lookup);
    autofix.add({
      'label': e.key,
      'source': e.value,
      'changed': changed,
      'light': {for (final c in d.light.entries) c.key: c.value.toARGB32()},
      'dark': {for (final c in d.dark.entries) c.key: c.value.toARGB32()},
    });
  }

  return {
    'note': 'สร้างโดย test/web_fixtures_test.dart — อย่าแก้มือ',
    'core': kNslCoreVersion,
    'schema': kNsltSchema,
    'userThemes': _userTexts,
    'resolve': resolve,
    'tint': tints,
    'parse': parse,
    'contrast': contrast,
    'autofix': autofix,
  };
}

void _check(String path, String want) {
  final f = File(path);
  if (_update) {
    f.createSync(recursive: true);
    f.writeAsStringSync(want);
  }
  expect(f.existsSync(), isTrue, reason: '$path ยังไม่มี — รัน NSL_UPDATE_FIXTURES=1 flutter test test/web_fixtures_test.dart');
  expect(f.readAsStringSync().replaceAll('\r\n', '\n') == want, isTrue,
      reason: '$path ไม่ตรงกับที่ nsl_ui สร้าง — รัน NSL_UPDATE_FIXTURES=1 flutter test test/web_fixtures_test.dart แล้วรัน npm test ใน web/');
}

void main() {
  test('fixture ของเว็บ NSL Palette ตรงกับ nsl_ui (core-fixtures.json)', () {
    _check('web/fixtures/core-fixtures.json', '${jsonEncode(_build())}\n');
  });

  test('ธีมในตัวที่เว็บโหลด (builtin-themes.json) ตรงกับ nsl_ui', () {
    _check('web/src/generated/builtin-themes.json', '${const JsonEncoder.withIndent('  ').convert(_builtinTexts)}\n');
  });

  test('fixture ครอบคลุมจริง: resolve ทั้งสำเร็จและ error, parse ทั้งผ่านและไม่ผ่าน, autofix มีการแก้จริง', () {
    final j = _build();
    final resolve = (j['resolve'] as List).cast<Map<String, Object?>>();
    expect(resolve.where((c) => c['error'] != null).length, greaterThanOrEqualTo(6));
    expect(resolve.where((c) => c['expected'] != null).length, greaterThan(100));
    final parse = (j['parse'] as List).cast<Map<String, Object?>>();
    expect(parse.where((c) => c['ok'] == true).length, greaterThan(40));
    expect(parse.where((c) => c['ok'] == false).length, greaterThan(40));
    final fix = (j['autofix'] as List).cast<Map<String, Object?>>();
    expect(fix.where((c) => (c['changed'] as int) > 0).length, greaterThanOrEqualTo(2));
    // 'already' = ธีมในตัวของ Dev ล้วน ๆ : ไม่ได้ "ผ่านทุกข้อ" — ตัวอักษรขาวบน accent โหมดมืดได้ 3.68:1 (ข้อค้นพบข้อ 1 ใน progress.md) autoFix จึงแตะ 1 ค่า
    expect(fix.firstWhere((c) => c['label'] == 'already')['changed'], 1);
  });
}
