import 'dart:ui';

import '../contrast/contrast.dart';
import '../tokens/color_tokens.dart';

/// รากของสี: ต้องระบุเสมอ (จากธีมฐานหรือผู้ใช้) ที่เหลือ derive ได้
const kRootColorKeys = <String>['bg', 'surface', 'text', 'accent'];

/// token ที่คำนวณจากสีหลัก (accent) — ถ้าผู้ใช้เปลี่ยน accent แต่ไม่ได้ระบุสามตัวนี้ ค่าที่สืบมาจากธีมฐานจะถูกทิ้งแล้วคำนวณใหม่
const kAccentDependents = <String>['accentInk', 'accentTint', 'onAccent', 'accentBorder'];

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// เติมสีที่ไม่ได้ระบุใน [given] ให้ครบทุก token ของ [brightness]
///
/// [given] ต้องมีอย่างน้อยสี root (`bg`, `surface`, `text`, `accent`) ; ค่าที่ระบุแล้วไม่ถูกแตะ
/// สูตรเป็นแบบ "ผสมสี" ล้วน ๆ จึงให้ผลที่อ่านออกในธีมที่ผู้ใช้ตั้งเอง
NslColors deriveColors(Map<String, Color> given, Brightness brightness) {
  for (final k in kRootColorKeys) {
    if (!given.containsKey(k)) {
      throw ArgumentError('deriveColors: missing root color "$k"');
    }
  }
  final light = brightness == Brightness.light;
  final v = <String, Color>{...given};

  final bg = v['bg']!, surface = v['surface']!, text = v['text']!, accent = v['accent']!;

  v['chrome'] ??= bg;
  v['surfaceRaised'] ??= surface;
  v['surfaceSunken'] ??= _mix(surface, text, 0.05);
  v['borderSoft'] ??= _mix(surface, text, 0.08);
  v['border'] ??= _mix(surface, text, 0.14);
  v['borderStrong'] ??= _mix(surface, text, 0.22);
  v['textMuted'] ??= _mix(text, surface, 0.38);
  v['textFaint'] ??= _mix(text, surface, 0.58);
  v['icon'] ??= _mix(text, v['textMuted']!, 0.3);
  v['accentInk'] ??= inkFor(accent, surface, light);
  v['accentTint'] ??= Color.alphaBlend(accent.withValues(alpha: 0.14), surface);
  v['onAccent'] ??= onAccentFor(accent);
  v['hover'] ??= _mix(surface, text, 0.06);
  v['selected'] ??= Color.alphaBlend(accent.withValues(alpha: 0.2), surface);
  v['accentBorder'] ??= Color.alphaBlend(accent.withValues(alpha: 0.45), surface);

  // สีสถานะ: ค่าเริ่มต้นคงที่ตามโหมด (ผู้ใช้ตั้งทับได้)
  v['danger'] ??= light ? const Color(0xFFB42318) : const Color(0xFFF97066);
  v['dangerBg'] ??= light ? const Color(0xFFFDE8E8) : const Color(0xFF3F1B1B);
  v['dangerText'] ??= light ? const Color(0xFF7A1F1F) : const Color(0xFFFCA5A5);
  v['warnBg'] ??= light ? const Color(0xFFFFF4D6) : const Color(0xFF3A2E10);
  v['warnText'] ??= light ? const Color(0xFF5C3D00) : const Color(0xFFF4D58A);
  v['infoBg'] ??= light ? const Color(0xFFE8EEF8) : const Color(0xFF1B2A44);
  v['infoText'] ??= light ? const Color(0xFF1E3A6B) : const Color(0xFF9DBBEA);
  v['success'] ??= light ? const Color(0xFF1A7F4B) : const Color(0xFF4ADE80);
  v['successBg'] ??= light ? const Color(0xFFE6F4EA) : const Color(0xFF12301F);
  v['successText'] ??= light ? const Color(0xFF14532D) : const Color(0xFF86EFAC);
  v['shadow'] ??= light ? const Color(0xFF0F172A) : const Color(0xFF000000);

  return NslColors.fromMap({for (final k in kCoreColorKeys) k: v[k]!});
}
