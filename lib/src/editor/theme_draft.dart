import 'dart:ui';

import '../contrast/contrast.dart';
import '../contrast/contrast_report.dart';
import '../format/resolve.dart';
import '../format/theme_spec.dart';
import '../tokens/nsl_tokens.dart';
import '../tokens/style_tokens.dart';

/// โมเดลแก้ไขธีมของ Theme Editor (ไม่มี UI) : แปลงจาก/เป็น [NslThemeSpec], resolve เพื่อพรีวิว,
/// ตรวจ contrast และแก้ให้ผ่านอัตโนมัติ — แยกจาก UI เพื่อทดสอบได้โดยตรง
class NslThemeDraft {
  NslThemeDraft({
    this.id = '',
    this.name = '',
    this.baseId = 'nsl.nebular',
    Map<String, Color>? light,
    Map<String, Color>? dark,
    this.radiusMd,
    this.scale,
    this.density,
    this.elevationMode,
    this.elevationStrength,
  })  : light = light ?? {},
        dark = dark ?? {};

  factory NslThemeDraft.fromSpec(NslThemeSpec s) => NslThemeDraft(
        id: s.id,
        name: s.name,
        baseId: s.extendsId ?? 'nsl.nebular',
        light: {...s.light.colors},
        dark: {...s.dark.colors},
        radiusMd: s.radius['md'],
        scale: s.scale,
        density: s.density,
        elevationMode: s.elevationMode,
        elevationStrength: s.elevationStrength,
      );

  String id, name, baseId;

  /// สีที่ผู้ใช้กำหนดเอง (เฉพาะที่ต่างจากธีมฐาน) แยกตามโหมด
  final Map<String, Color> light, dark;
  double? radiusMd, scale, elevationStrength;
  NslDensity? density;
  NslElevationMode? elevationMode;

  Map<String, Color> colorsOf(Brightness b) => b == Brightness.light ? light : dark;

  /// ชื่อ → id ที่ใช้เป็นชื่อไฟล์ได้ (a-z 0-9 . _ -) ; ชื่อไทยล้วนได้ 'theme'
  static String slugify(String name) {
    var s = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]+'), '-').replaceAll(RegExp(r'^[^a-z0-9]+|-+$'), '');
    if (s.isEmpty) s = 'theme';
    return s.length > 64 ? s.substring(0, 64) : s;
  }

  NslThemeSpec toSpec() => NslThemeSpec(
        id: id.isEmpty ? slugify(name) : id,
        name: name.isEmpty ? 'Theme' : name,
        extendsId: baseId,
        light: NslModeSpec(colors: {...light}),
        dark: NslModeSpec(colors: {...dark}),
        radius: {'md': ?radiusMd},
        scale: scale,
        density: density,
        elevationMode: elevationMode,
        elevationStrength: elevationStrength,
      );

  /// resolve เพื่อพรีวิว ; โยน [NslResolveException] ถ้าธีมฐานหาย
  NslTokens resolve(Brightness b, NslThemeLookup lookup) => resolveTokens(toSpec(), b, lookup: lookup);

  List<ContrastCheck> failures(Brightness b, NslThemeLookup lookup) => contrastFailures(resolve(b, lookup));

  /// แก้รายการที่ contrast ไม่ผ่านโดยขยับสีตัวอักษร/เส้นขอบ (ไม่แตะพื้น/accent ที่ผู้ใช้เลือก)
  /// คืนจำนวนค่าที่ปรับ ; ทำสูงสุด 3 รอบเพราะบางสีคำนวณต่อจากกัน
  int autoFix(NslThemeLookup lookup) {
    var changed = 0;
    for (final b in [Brightness.light, Brightness.dark]) {
      for (var pass = 0; pass < 3; pass++) {
        final t = resolve(b, lookup);
        final fails = contrastFailures(t);
        if (fails.isEmpty) break;
        for (final f in fails) {
          final fg = t.colors[f.fg], bg = t.colors[f.bg];
          // ขยับตามทิศปกติของโหมดก่อน ; ถ้ายังไม่ถึงเกณฑ์ (เช่น ขาวบน accent สว่าง) ลองอีกทิศ
          var fixed = ensureContrast(fg, bg, f.min, light: !t.isDark);
          if (contrastRatio(fixed, bg) < f.min) {
            final other = ensureContrast(fg, bg, f.min, light: t.isDark);
            if (contrastRatio(other, bg) > contrastRatio(fixed, bg)) fixed = other;
          }
          if (fixed != fg) {
            colorsOf(b)[f.fg] = fixed;
            changed++;
          }
        }
      }
    }
    return changed;
  }
}
