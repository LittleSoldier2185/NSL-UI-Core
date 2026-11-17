import 'dart:ui';

import 'color_tokens.dart';
import 'style_tokens.dart';

/// token ทั้งหมดของหนึ่งโหมด (สว่างหรือมืด) ที่ resolve ครบแล้ว — ค่าที่แอปอ่านใช้จริง
class NslTokens {
  const NslTokens({
    required this.brightness,
    required this.colors,
    this.shape = const NslShape(),
    this.type = const NslType(),
    this.density = NslDensity.normal,
    this.elevation = const NslElevation(),
    this.extensions = const {},
  });

  final Brightness brightness;
  final NslColors colors;
  final NslShape shape;
  final NslType type;
  final NslDensity density;
  final NslElevation elevation;

  /// token เฉพาะแอป แยกตามชื่อส่วนขยาย เช่น `dev` -> {tableHead: ..., dot: ...}
  final Map<String, Map<String, Color>> extensions;

  bool get isDark => brightness == Brightness.dark;

  /// แผนที่แบน ชื่อ → ARGB (int) สำหรับส่งให้โค้ด native (เช่น วิดเจ็ตหน้าจอหลักของ Android)
  /// สี core ใช้ชื่อตรง ๆ (`accent`) ; สีของส่วนขยายใช้ `<ส่วนขยาย>.<คีย์>` (`nebular.canvas`)
  Map<String, int> toArgbMap() => {
        for (final k in kCoreColorKeys) k: colors[k].toARGB32(),
        for (final e in extensions.entries)
          for (final c in e.value.entries) '${e.key}.${c.key}': c.value.toARGB32(),
      };

  /// สีของส่วนขยาย [ext] ชื่อ [key] (null ถ้าไม่มี)
  Color? ext(String ext, String key) => extensions[ext]?[key];

  @override
  bool operator ==(Object other) {
    if (other is! NslTokens) return false;
    if (brightness != other.brightness ||
        colors != other.colors ||
        shape != other.shape ||
        type != other.type ||
        density != other.density ||
        elevation != other.elevation ||
        extensions.length != other.extensions.length) {
      return false;
    }
    for (final e in extensions.entries) {
      final o = other.extensions[e.key];
      if (o == null || o.length != e.value.length) return false;
      for (final c in e.value.entries) {
        if (o[c.key] != c.value) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(brightness, colors, shape, type, density, elevation, extensions.length);
}
