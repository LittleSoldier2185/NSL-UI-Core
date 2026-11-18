import 'dart:convert';
import 'dart:ui';

import '../tokens/style_tokens.dart';
import 'theme_spec.dart';

/// ขนาดไฟล์ `.nslt` สูงสุด (ไบต์) — ใหญ่กว่านี้ปฏิเสธโดยไม่อ่าน
const kNsltMaxBytes = 64 * 1024;

const _maxNameLen = 80;
const _maxFamilyLen = 64;
final _idRe = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');
final _coreRe = RegExp(r'^\d{1,3}\.\d{1,3}$');
final _hexRe = RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

/// ผลการอ่านไฟล์ธีม: ถ้า [spec] เป็น null แปลว่าอ่านไม่ได้ ดู [errors] ; [warnings] คือค่าที่ถูกข้าม/ปรับ
class NsltParseResult {
  const NsltParseResult({this.spec, this.errors = const [], this.warnings = const []});
  final NslThemeSpec? spec;
  final List<String> errors;
  final List<String> warnings;
  bool get ok => spec != null;
}

/// อ่านไฟล์ธีมจากข้อความ — **ไม่โยน exception ไม่ว่าอินพุตจะเสียอย่างไร**
///
/// ข้อมูลเป็นของไม่น่าเชื่อถือ: จำกัดขนาด, อนุญาตเฉพาะรูปแบบที่รู้จัก, clamp ตัวเลข, ไม่มีฟิลด์ที่เป็น path/URL
NsltParseResult parseNslt(String source) {
  try {
    return _parse(source);
  } catch (e) {
    // ตาข่ายสุดท้าย: ไม่ควรมาถึงที่นี่ ถ้ามาแปลว่ามีกรณีที่ยังไม่ครอบคลุม แต่ต้องไม่ทำให้แอปล้ม
    return NsltParseResult(errors: ['unexpected error while reading theme: ${e.runtimeType}']);
  }
}

NsltParseResult _parse(String source) {
  if (utf8.encode(source).length > kNsltMaxBytes) {
    return const NsltParseResult(errors: ['file too large (> 64 KB)']);
  }
  final Object? root;
  try {
    root = jsonDecode(source);
  } on FormatException catch (e) {
    return NsltParseResult(errors: ['not valid JSON: ${e.message}']);
  }
  if (root is! Map<String, Object?>) {
    return const NsltParseResult(errors: ['top level must be a JSON object']);
  }

  final warnings = <String>[];

  final schema = root['schema'];
  if (schema is! int || schema < 1) {
    return const NsltParseResult(errors: ['"schema" must be an integer >= 1']);
  }
  if (schema > kNsltSchema) {
    return NsltParseResult(errors: ['theme schema $schema is newer than supported ($kNsltSchema) — update the app']);
  }

  final id = root['id'];
  if (id is! String || !_idRe.hasMatch(id)) {
    return const NsltParseResult(errors: ['"id" must match [a-z0-9][a-z0-9._-]{0,63}']);
  }
  var name = root['name'];
  if (name is! String || name.trim().isEmpty) {
    warnings.add('"name" missing — using id');
    name = id;
  } else if (name.length > _maxNameLen) {
    warnings.add('"name" too long — truncated');
    name = name.substring(0, _maxNameLen);
  }

  String? core;
  final coreV = root['core'];
  if (coreV != null) {
    if (coreV is String && _coreRe.hasMatch(coreV)) {
      core = coreV;
      if (_coreNewer(coreV)) {
        warnings.add('theme made with newer core $coreV (this is $kNslCoreVersion) — unknown values are kept but not applied');
      }
    } else {
      warnings.add('"core" must look like "1.0" — ignored');
    }
  }

  String? extendsId;
  final ext = root['extends'];
  if (ext != null) {
    if (ext is String && _idRe.hasMatch(ext)) {
      extendsId = ext;
    } else {
      warnings.add('"extends" ignored (not a valid id)');
    }
  }

  final light = _parseMode(root['light'], 'light', warnings);
  final dark = _parseMode(root['dark'], 'dark', warnings);

  // shape
  final radius = <String, double>{};
  final shape = root['shape'];
  if (shape is Map<String, Object?>) {
    final r = shape['radius'];
    if (r is Map<String, Object?>) {
      for (final e in r.entries) {
        if (!NslShape.keys.contains(e.key)) {
          warnings.add('shape.radius.${e.key} unknown — ignored');
          continue;
        }
        final v = _num(e.value);
        if (v == null) {
          warnings.add('shape.radius.${e.key} is not a finite number — ignored');
          continue;
        }
        radius[e.key] = _clamp(v, NslShape.minRadius, NslShape.maxRadius, 'shape.radius.${e.key}', warnings);
      }
    }
  }

  // type
  String? family, content, mono, familyThai, contentThai, monoThai;
  double? scale, minSize;
  final type = root['type'];
  if (type is Map<String, Object?>) {
    family = _fontName(type['family'], 'type.family', warnings);
    content = _fontName(type['content'], 'type.content', warnings);
    mono = _fontName(type['mono'], 'type.mono', warnings);
    familyThai = _fontName(type['familyThai'], 'type.familyThai', warnings);
    contentThai = _fontName(type['contentThai'], 'type.contentThai', warnings);
    monoThai = _fontName(type['monoThai'], 'type.monoThai', warnings);
    if (type.containsKey('minSize')) {
      final v = _num(type['minSize']);
      if (v == null) {
        warnings.add('type.minSize is not a finite number — ignored');
      } else {
        minSize = _clamp(v, NslType.minMinSize, NslType.maxMinSize, 'type.minSize', warnings);
      }
    }
    if (type.containsKey('scale')) {
      final v = _num(type['scale']);
      if (v == null) {
        warnings.add('type.scale is not a finite number — ignored');
      } else {
        scale = _clamp(v, NslType.minScale, NslType.maxScale, 'type.scale', warnings);
      }
    }
  }

  NslDensity? density;
  if (root.containsKey('density')) {
    density = NslDensity.parse(root['density']);
    if (density == null) warnings.add('"density" must be compact|normal|comfortable — ignored');
  }

  NslElevationMode? emode;
  double? estrength;
  final el = root['elevation'];
  if (el is Map<String, Object?>) {
    if (el.containsKey('mode')) {
      emode = NslElevationMode.parse(el['mode']);
      if (emode == null) warnings.add('elevation.mode must be shadow|flat — ignored');
    }
    if (el.containsKey('strength')) {
      final v = _num(el['strength']);
      if (v == null) {
        warnings.add('elevation.strength is not a finite number — ignored');
      } else {
        estrength = _clamp(v, NslElevation.minStrength, NslElevation.maxStrength, 'elevation.strength', warnings);
      }
    }
  }

  // apps : รายชื่อ id แอป (ไม่ซ้ำ, ≤ 16) — ผิดรูปแบบ = เตือนและเก็บค่าดิบไว้ใน unknown เพื่อไม่ให้ข้อมูลหาย
  var apps = <String>[];
  var appsRaw = false;
  final appsV = root['apps'];
  if (appsV != null) {
    if (appsV is List && appsV.length <= 16 && appsV.every((e) => e is String && _idRe.hasMatch(e))) {
      apps = [...{...appsV.cast<String>()}];
    } else {
      warnings.add('"apps" must be a list of up to 16 app ids — ignored');
      appsRaw = true;
    }
  }

  const known = {'schema', 'core', 'id', 'name', 'extends', 'light', 'dark', 'shape', 'type', 'density', 'elevation', 'apps'};
  final unknown = <String, Object?>{for (final e in root.entries) if (!known.contains(e.key)) e.key: e.value, if (appsRaw) 'apps': appsV};
  // คีย์ใน type ที่รุ่นนี้ไม่รู้จัก (เช่น ฟอนต์บทบาทใหม่ของ core รุ่นหลัง) เก็บไว้ใต้ unknown['type'] แล้วผสานกลับตอนเขียน — ไม่ให้หายเมื่อแอปรุ่นเก่าบันทึกทับ
  if (type is Map<String, Object?>) {
    const knownType = {'family', 'content', 'mono', 'familyThai', 'contentThai', 'monoThai', 'minSize', 'scale'};
    final extra = <String, Object?>{for (final e in type.entries) if (!knownType.contains(e.key)) e.key: e.value};
    if (extra.isNotEmpty) unknown['type'] = extra;
  }

  return NsltParseResult(
    spec: NslThemeSpec(
      schema: schema,
      core: core,
      id: id,
      name: name,
      extendsId: extendsId,
      light: light,
      dark: dark,
      radius: radius,
      family: family,
      content: content,
      mono: mono,
      familyThai: familyThai,
      contentThai: contentThai,
      monoThai: monoThai,
      minSize: minSize,
      scale: scale,
      density: density,
      elevationMode: emode,
      elevationStrength: estrength,
      apps: apps,
      unknown: unknown,
    ),
    warnings: warnings,
  );
}

NslModeSpec _parseMode(Object? v, String path, List<String> warnings) {
  if (v == null) return const NslModeSpec();
  if (v is! Map<String, Object?>) {
    warnings.add('"$path" must be an object — ignored');
    return const NslModeSpec();
  }
  final colors = <String, Color>{};
  final c = v['colors'];
  if (c is Map<String, Object?>) {
    for (final e in c.entries) {
      final col = _color(e.value);
      if (col == null) {
        warnings.add('$path.colors.${e.key}: invalid color — ignored');
      } else {
        colors[e.key] = col;
      }
    }
  } else if (c != null) {
    warnings.add('$path.colors must be an object — ignored');
  }
  final exts = <String, Map<String, Color>>{};
  final x = v['extensions'];
  if (x is Map<String, Object?>) {
    for (final e in x.entries) {
      final m = e.value;
      if (m is! Map<String, Object?>) {
        warnings.add('$path.extensions.${e.key} must be an object — ignored');
        continue;
      }
      final cm = <String, Color>{};
      for (final k in m.entries) {
        final col = _color(k.value);
        if (col == null) {
          warnings.add('$path.extensions.${e.key}.${k.key}: invalid color — ignored');
        } else {
          cm[k.key] = col;
        }
      }
      exts[e.key] = cm;
    }
  } else if (x != null) {
    warnings.add('$path.extensions must be an object — ignored');
  }
  return NslModeSpec(colors: colors, extensions: exts);
}

/// เวอร์ชัน core [v] ใหม่กว่ารุ่นนี้หรือไม่ (เทียบ major.minor เป็นตัวเลข)
bool _coreNewer(String v) {
  List<int> p(String x) => x.split('.').map(int.parse).toList();
  final a = p(v), b = p(kNslCoreVersion);
  return a[0] != b[0] ? a[0] > b[0] : a[1] > b[1];
}

/// อ่านสีรูปแบบ `#RRGGBB` / `#RRGGBBAA` (รูปแบบเดียวกับไฟล์ธีม) ; อย่างอื่น = null
Color? parseHexColor(String v) => _color(v);

Color? _color(Object? v) {
  if (v is! String || !_hexRe.hasMatch(v)) return null;
  final hex = v.substring(1);
  final rgb = int.parse(hex.substring(0, 6), radix: 16);
  final a = hex.length == 8 ? int.parse(hex.substring(6, 8), radix: 16) : 0xFF;
  return Color((a << 24) | rgb);
}

double? _num(Object? v) {
  if (v is! num) return null;
  final d = v.toDouble();
  return d.isFinite ? d : null;
}

double _clamp(double v, double lo, double hi, String path, List<String> warnings) {
  if (v < lo || v > hi) {
    final c = v < lo ? lo : hi;
    warnings.add('$path = $v out of range [$lo, $hi] — using $c');
    return c;
  }
  return v;
}

String? _fontName(Object? v, String path, List<String> warnings) {
  if (v == null) return null;
  if (v is! String || v.trim().isEmpty || v.length > _maxFamilyLen || RegExp(r'[\\/:\x00-\x1f]').hasMatch(v)) {
    warnings.add('$path: invalid font name — ignored');
    return null;
  }
  return v.trim();
}

// ---------------------------------------------------------------------------
// เขียนไฟล์

String _hex(Color c) {
  final v = c.toARGB32();
  final a = (v >> 24) & 0xFF;
  final rgb = (v & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  return a == 0xFF ? '#$rgb' : '#$rgb${a.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}

Map<String, Object?> _modeJson(NslModeSpec m) {
  final out = <String, Object?>{};
  if (m.colors.isNotEmpty) {
    out['colors'] = {for (final k in (m.colors.keys.toList()..sort())) k: _hex(m.colors[k]!)};
  }
  if (m.extensions.isNotEmpty) {
    out['extensions'] = {
      for (final e in (m.extensions.keys.toList()..sort()))
        e: {for (final k in (m.extensions[e]!.keys.toList()..sort())) k: _hex(m.extensions[e]![k]!)},
    };
  }
  return out;
}

/// แปลงเป็นข้อความ JSON (เรียงคีย์คงที่ จึงเทียบ/diff ได้) — คีย์ที่ไม่รู้จักถูกเขียนกลับครบ
String serializeNslt(NslThemeSpec s) {
  final out = <String, Object?>{
    'schema': s.schema,
    if (s.core != null) 'core': s.core,
    'id': s.id,
    'name': s.name,
    if (s.extendsId != null) 'extends': s.extendsId,
    if (s.apps.isNotEmpty) 'apps': s.apps,
  };
  final light = _modeJson(s.light), dark = _modeJson(s.dark);
  if (light.isNotEmpty) out['light'] = light;
  if (dark.isNotEmpty) out['dark'] = dark;
  if (s.radius.isNotEmpty) {
    out['shape'] = {
      'radius': {for (final k in NslShape.keys) if (s.radius.containsKey(k)) k: _jsonNum(s.radius[k]!)},
    };
  }
  final type = <String, Object?>{
    if (s.family != null) 'family': s.family,
    if (s.content != null) 'content': s.content,
    if (s.mono != null) 'mono': s.mono,
    if (s.familyThai != null) 'familyThai': s.familyThai,
    if (s.contentThai != null) 'contentThai': s.contentThai,
    if (s.monoThai != null) 'monoThai': s.monoThai,
    if (s.minSize != null) 'minSize': _jsonNum(s.minSize!),
    if (s.scale != null) 'scale': _jsonNum(s.scale!),
  };
  final extraType = s.unknown['type'];
  if (extraType is Map) {
    for (final e in extraType.entries) {
      if (e.key is String) type.putIfAbsent(e.key as String, () => e.value);
    }
  }
  if (type.isNotEmpty) out['type'] = type;
  if (s.density != null) out['density'] = s.density!.name;
  final el = <String, Object?>{
    if (s.elevationMode != null) 'mode': s.elevationMode!.name,
    if (s.elevationStrength != null) 'strength': _jsonNum(s.elevationStrength!),
  };
  if (el.isNotEmpty) out['elevation'] = el;
  for (final e in s.unknown.entries) {
    out.putIfAbsent(e.key, () => e.value);
  }
  return const JsonEncoder.withIndent('  ').convert(out);
}

/// ตัวเลขที่เป็นจำนวนเต็มเขียนเป็นจำนวนเต็ม (8 ไม่ใช่ 8.0)
Object _jsonNum(double v) => v == v.roundToDouble() ? v.toInt() : v;
