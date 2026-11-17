import 'dart:ui';

import '../contrast/contrast.dart';
import '../derive/derive.dart';
import '../tokens/extensions.dart';
import '../tokens/nsl_tokens.dart';
import '../tokens/style_tokens.dart';
import 'theme_spec.dart';

/// หาธีมฐานจาก id (คืน null ถ้าไม่มี)
typedef NslThemeLookup = NslThemeSpec? Function(String id);

/// ความลึกสูงสุดของสายการสืบทอด (กันวนลูป)
const kMaxExtendsDepth = 8;

class NslResolveException implements Exception {
  NslResolveException(this.message);
  final String message;
  @override
  String toString() => 'NslResolveException: $message';
}

/// รวมสายการสืบทอดของ [spec] เป็นรายการจากฐานสุดไปถึง [spec] เอง
List<NslThemeSpec> _chain(NslThemeSpec spec, NslThemeLookup lookup) {
  final out = <NslThemeSpec>[spec];
  final seen = <String>{spec.id};
  var cur = spec;
  while (cur.extendsId != null) {
    if (out.length > kMaxExtendsDepth) {
      throw NslResolveException('extends chain too deep (> $kMaxExtendsDepth)');
    }
    final base = lookup(cur.extendsId!);
    if (base == null) {
      throw NslResolveException('base theme "${cur.extendsId}" not found');
    }
    if (!seen.add(base.id)) {
      throw NslResolveException('extends cycle at "${base.id}"');
    }
    out.insert(0, base);
    cur = base;
  }
  return out;
}

/// resolve ธีม [spec] ของโหมด [brightness] เป็น token ที่ครบทุกค่า
///
/// ลำดับ: ค่าจากธีมฐาน → ทับด้วยธีมลูก → derive ค่าที่ยังขาด
/// กติกาพิเศษ: ถ้าธีมลูกเปลี่ยน `accent` แต่ไม่ได้ระบุ `accentInk/accentTint/onAccent`
/// ค่าสามตัวนี้ที่สืบมาจากฐานจะถูกทิ้งและคำนวณใหม่ให้เข้ากับ accent ใหม่
/// ถ้าสืบทอดแล้วยังไม่มีสี root ครบ (`bg`, `surface`, `text`, `accent`) จะโยน [NslResolveException]
NslTokens resolveTokens(NslThemeSpec spec, Brightness brightness, {NslThemeLookup? lookup}) {
  final chain = _chain(spec, lookup ?? (_) => null);

  final colors = <String, Color>{};
  final exts = <String, Map<String, Color>>{};
  final radius = <String, double>{};
  String? family, content, mono;
  double? scale, strength, minSize;
  NslDensity? density;
  NslElevationMode? mode;

  for (final s in chain) {
    final m = s.mode(brightness);
    if (m.colors.containsKey('accent') && s != chain.first) {
      // ธีมลูกที่ไม่ใช่ฐานสุดเปลี่ยน accent → ล้างตัวที่คำนวณจาก accent ก่อนทับ
      for (final k in kAccentDependents) {
        if (!m.colors.containsKey(k)) colors.remove(k);
      }
      for (final def in kKnownExtensions) {
        for (final k in def.accentDependents) {
          if (m.extensions[def.name]?.containsKey(k) != true) exts[def.name]?.remove(k);
        }
      }
    }
    colors.addAll(m.colors);
    for (final e in m.extensions.entries) {
      (exts[e.key] ??= {}).addAll(e.value);
    }
    radius.addAll(s.radius);
    family = s.family ?? family;
    content = s.content ?? content;
    minSize = s.minSize ?? minSize;
    mono = s.mono ?? mono;
    scale = s.scale ?? scale;
    density = s.density ?? density;
    mode = s.elevationMode ?? mode;
    strength = s.elevationStrength ?? strength;
  }

  // ค่า lite ของผู้ใช้ชนะทุกอย่าง (เฉพาะ accent) : ล้างค่าที่คำนวณจาก accent แล้วใส่ชุดของโหมดนี้
  final lite = spec.appearance?.accentSet(brightness == Brightness.dark);
  if (lite != null) {
    for (final k in kAccentDependents) {
      colors.remove(k);
    }
    colors['accent'] = lite.$1;
    colors['accentTint'] = lite.$2;
    colors['accentInk'] = lite.$3;
    colors['onAccent'] = onAccentFor(lite.$1);
    for (final def in kKnownExtensions) {
      for (final k in def.accentDependents) {
        exts[def.name]?.remove(k);
      }
    }
  }

  final missing = [for (final k in kRootColorKeys) if (!colors.containsKey(k)) k];
  if (missing.isNotEmpty) {
    throw NslResolveException('missing root colors: ${missing.join(', ')} (set them or use "extends")');
  }

  final core = deriveColors(colors, brightness);

  // ส่วนขยายที่รู้จัก: เติมค่า derive ; ส่วนขยายที่ไม่รู้จักผ่านไปตามเดิม
  final outExt = <String, Map<String, Color>>{};
  for (final def in kKnownExtensions) {
    final given = exts[def.name] ?? const <String, Color>{};
    final derived = def.derive(core, brightness);
    outExt[def.name] = {
      for (final k in def.keys) k: given[k] ?? derived[k]!,
    };
  }
  for (final e in exts.entries) {
    outExt.putIfAbsent(e.key, () => Map.unmodifiable(e.value));
  }

  return NslTokens(
    brightness: brightness,
    colors: core,
    shape: const NslShape().withValues(radius),
    type: NslType(family: family, content: content, mono: mono, scale: scale ?? 1.0, minSize: minSize),
    density: density ?? NslDensity.normal,
    elevation: NslElevation(mode: mode ?? NslElevationMode.shadow, strength: strength ?? 1.0),
    extensions: outExt,
  );
}
