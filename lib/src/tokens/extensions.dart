import 'dart:ui';

import '../appearance/accent_presets.dart';
import 'color_tokens.dart';

/// นิยามส่วนขยาย token เฉพาะแอป: ชื่อ, คีย์ที่รู้จัก, และวิธี derive ค่าที่ธีมไม่ได้ระบุจากสี core
///
/// ธีมที่ตั้งแค่สี core ก็ยังใช้ได้ครบ เพราะส่วนขยายมีค่า derive ให้เสมอ
class NslExtensionDef {
  const NslExtensionDef(this.name, this.keys, this.derive, {this.accentDependents = const []});

  final String name;
  final List<String> keys;

  /// คีย์ที่คำนวณจาก accent — ถ้าธีมลูก (หรือค่า lite) เปลี่ยน accent โดยไม่ระบุคีย์เหล่านี้ ค่าที่สืบมาจากฐานจะถูกทิ้งแล้วคำนวณใหม่
  /// (เหมือนกติกาของ `kAccentDependents` ในสี core)
  final List<String> accentDependents;

  /// คืนค่าเริ่มต้นของ [keys] ทุกตัวจากสี core ของโหมดนั้น
  final Map<String, Color> Function(NslColors core, Brightness brightness) derive;
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// ส่วนขยายของ NSL Dev (แคนวาส ER/DFD: พื้นกระดาน, หัวตาราง, ป้าย PK/UQ/NN, ไฮไลต์ FK)
const kDevExtension = NslExtensionDef('nebular', [
  'canvas',
  'dot',
  'tableHead',
  'pkBg',
  'pkText',
  'uqBg',
  'uqText',
  'nnBg',
  'nnText',
  'boardOutside',
  'boardEdge',
  'fkSource',
  'fkChip',
], _deriveDev, accentDependents: ['fkChip']);

Map<String, Color> _deriveDev(NslColors c, Brightness b) {
  final light = b == Brightness.light;
  return {
    'canvas': _mix(c.bg, c.surface, 0.5),
    'dot': c.border,
    'tableHead': light ? c.text : _mix(c.surface, c.text, 0.12),
    'pkBg': light ? const Color(0xFFFDEBD3) : const Color(0xFF4A3213),
    'pkText': light ? const Color(0xFF8A4B08) : const Color(0xFFF5B66B),
    'uqBg': light ? const Color(0xFFEDE9FE) : const Color(0xFF2E2552),
    'uqText': light ? const Color(0xFF5B21B6) : const Color(0xFFC4B0FA),
    'nnBg': _mix(c.surface, c.text, 0.10),
    'nnText': _mix(c.text, c.surface, 0.15),
    'boardOutside': _mix(c.bg, const Color(0xFF000000), light ? 0.05 : 0.3),
    'boardEdge': _mix(c.surface, c.text, 0.3),
    'fkSource': light ? const Color(0xFFFFE9A8) : const Color(0xFF5A4A12),
    'fkChip': Color.alphaBlend(c.accent.withValues(alpha: 0.2), c.surface),
  };
}

/// ส่วนขยายของ NSL Resonance (ปลายด้านล่างของพื้นแผงที่ไล่เฉด)
const kResonanceExtension = NslExtensionDef('spectrum', ['panelBottom'], _deriveResonance);

Map<String, Color> _deriveResonance(NslColors c, Brightness b) => {
      'panelBottom': _mix(c.surface, c.bg, 0.7),
    };

/// ชื่อคีย์ของสีประเภทรายการและป้ายสถานะใน [kLyraExtension] (ตรงกับ enum ของแอป Lyra)
const kLyraTypes = <String>['character', 'place', 'org', 'event', 'item', 'rule', 'species'];
const kLyraStatuses = <String>['idea', 'draft', 'canon'];

/// ส่วนขยายของ Lyra (NSL Writer Tools): โทนตัวอักษรเนื้อหา, เส้นและกราฟ, สีประเภท 7 แบบ, ป้ายสถานะ 3 แบบ (พื้น/ตัวอักษร)
/// เพิ่มใน core 1.1 — ธีมที่ไม่ระบุได้ค่า derive จากสี core เสมอ
const kLyraExtension = NslExtensionDef('lyra', [
  'body',
  'accentDark',
  'summary',
  'snippet',
  'chipText',
  'border',
  'dash',
  'edge',
  'navIndicator',
  'typeCharacter',
  'typePlace',
  'typeOrg',
  'typeEvent',
  'typeItem',
  'typeRule',
  'typeSpecies',
  'statusIdeaBg',
  'statusIdeaFg',
  'statusDraftBg',
  'statusDraftFg',
  'statusCanonBg',
  'statusCanonFg',
], _deriveLyra, accentDependents: ['accentDark']);

Map<String, Color> _deriveLyra(NslColors c, Brightness b) {
  final dark = b == Brightness.dark;
  // ประเภทรายการใช้ชุด categorical ของ core (ลำดับคงที่) เมื่อธีมไม่ระบุสีของตัวเอง
  Color cat(int i) => kAccentPresets[i].set(dark).$1;
  return {
    'body': c.text,
    'accentDark': _mix(c.accent, const Color(0xFF000000), 0.15),
    'summary': _mix(c.text, c.surface, 0.12),
    'snippet': _mix(c.text, c.surface, 0.25),
    'chipText': _mix(c.text, c.surface, 0.18),
    'border': _mix(c.border, c.borderStrong, 0.5),
    'dash': c.textFaint,
    'edge': c.textFaint,
    'navIndicator': c.selected,
    'typeCharacter': cat(6),
    'typePlace': cat(5),
    'typeOrg': cat(1),
    'typeEvent': cat(4),
    'typeItem': cat(2),
    'typeRule': cat(0),
    'typeSpecies': cat(3),
    'statusIdeaBg': c.surfaceSunken,
    'statusIdeaFg': c.textMuted,
    'statusDraftBg': c.warnBg,
    'statusDraftFg': c.warnText,
    'statusCanonBg': c.successBg,
    'statusCanonFg': c.successText,
  };
}

/// ส่วนขยายที่รู้จักทั้งหมด (แอปใหม่เพิ่มของตัวเองที่นี่)
const kKnownExtensions = <NslExtensionDef>[kDevExtension, kResonanceExtension, kLyraExtension];
