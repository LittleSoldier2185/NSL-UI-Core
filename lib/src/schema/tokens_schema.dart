import 'dart:convert';
import 'dart:ui';

import '../appearance/accent_presets.dart';
import '../appearance/appearance.dart';
import '../builtin/builtin_themes.dart';
import '../derive/derive.dart';
import '../derive/tint.dart';
import '../format/theme_spec.dart';
import '../tokens/color_tokens.dart';
import '../tokens/extensions.dart';
import '../tokens/style_tokens.dart';

/// กลุ่มของสี core (ไว้จัดหมวดในฟอร์มของ NSL Palette)
const _colorGroups = <String, String>{
  'bg': 'surfaces',
  'chrome': 'surfaces',
  'surface': 'surfaces',
  'surfaceRaised': 'surfaces',
  'surfaceSunken': 'surfaces',
  'hover': 'surfaces',
  'selected': 'surfaces',
  'borderSoft': 'borders',
  'border': 'borders',
  'borderStrong': 'borders',
  'text': 'text',
  'textMuted': 'text',
  'textFaint': 'text',
  'icon': 'text',
  'accent': 'accent',
  'accentInk': 'accent',
  'accentTint': 'accent',
  'accentBorder': 'accent',
  'onAccent': 'accent',
  'danger': 'status',
  'dangerBg': 'status',
  'dangerText': 'status',
  'warnBg': 'status',
  'warnText': 'status',
  'infoBg': 'status',
  'infoText': 'status',
  'success': 'status',
  'successBg': 'status',
  'successText': 'status',
  'shadow': 'other',
};

/// เวอร์ชัน core ที่ token เริ่มมี (ที่ไม่ระบุ = "1.0") — เพิ่มที่นี่ทุกครั้งที่เพิ่ม token ใหม่ใน minor ถัดไป
const _since = <String, String>{};

/// แอปที่ใช้ส่วนขยาย (ชื่อที่ผู้ใช้เห็น)
const _extensionApps = <String, String>{
  'nebular': 'Nebular (NSL Dev)',
  'spectrum': 'Spectrum (NSL Resonance)',
  'lyra': 'Lyra (NSL Writer Tools)',
};

/// เวอร์ชัน core ที่ส่วนขยายเริ่มมี (ที่ไม่ระบุ = "1.0")
const _extensionSince = <String, String>{'lyra': '1.1'};

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// ชุดสี accent เป็น hex (accent = สีหลัก, soft = พื้นอ่อน, ink = ตัวอักษรบนพื้นอ่อน)
Map<String, String> _set(NslAccentSet s) => {'accent': _hex(s.$1), 'soft': _hex(s.$2), 'ink': _hex(s.$3)};

/// สร้าง schema ของ token ทั้งหมดเป็นข้อมูลล้วน — **แหล่งความจริงเดียว** ที่เว็บ NSL Palette อ่านไปสร้างฟอร์ม
/// (token ใหม่จึงโผล่ใน editor เองโดยไม่ต้องเขียน UI เพิ่ม) ; ไฟล์ `schema/tokens.schema.json` สร้างจากฟังก์ชันนี้
/// และมีเทสต์ตรวจว่าตรงกันเสมอ
Map<String, Object?> buildTokensSchema() {
  const shape = NslShape();
  return {
    'schema': kNsltSchema,
    'core': kNslCoreVersion,
    'colors': [
      for (final k in kCoreColorKeys)
        {
          'key': k,
          'group': _colorGroups[k] ?? 'other',
          'root': kRootColorKeys.contains(k),
          'accentDependent': kAccentDependents.contains(k),
          'since': _since[k] ?? '1.0',
        },
    ],
    'extensions': [
      for (final e in kKnownExtensions)
        {
          'name': e.name,
          'app': _extensionApps[e.name] ?? e.name,
          'keys': e.keys,
          'accentDependents': e.accentDependents,
          'since': _extensionSince[e.name] ?? '1.0',
        },
    ],
    'shape': {
      'radius': {
        'keys': NslShape.keys,
        'default': shape.toMap(),
        'min': NslShape.minRadius,
        'max': NslShape.maxRadius,
      },
    },
    'type': {
      'roles': ['family', 'content', 'mono'],
      'scale': {'min': NslType.minScale, 'max': NslType.maxScale, 'default': 1.0},
      'minSize': {'min': NslType.minMinSize, 'max': NslType.maxMinSize},
      'fontNameMaxLength': 64,
    },
    'density': [for (final d in NslDensity.values) d.name],
    'elevation': {
      'modes': [for (final m in NslElevationMode.values) m.name],
      'strength': {'min': NslElevation.minStrength, 'max': NslElevation.maxStrength, 'default': 1.0},
    },
    'appearance': {
      'modes': [for (final m in NslModeChoice.values) m.name],
      'presets': [
        for (final p in kAccentPresets)
          {
            'id': p.id,
            'nameTh': p.nameTh,
            'nameEn': p.nameEn,
            'light': _set(p.light),
            'dark': _set(p.dark),
          },
      ],
    },
    'builtinThemes': [
      for (final id in kBuiltinThemeIds) {'id': id, 'name': builtinThemeById(id)?.name ?? id},
    ],
    'limits': {'maxFileBytes': 64 * 1024, 'idPattern': r'^[a-z0-9][a-z0-9._-]{0,63}$', 'reservedIdPrefix': 'nsl.'},
  };
}

/// ข้อความ JSON ของ [buildTokensSchema] (เยื้อง 2 ช่อง ลงท้ายด้วยบรรทัดใหม่)
String tokensSchemaJson() => '${const JsonEncoder.withIndent('  ').convert(buildTokensSchema())}\n';
