import 'dart:ui';

import 'package:flutter/material.dart' show ThemeMode;

import '../derive/tint.dart';
import 'accent_presets.dart';

/// โหมดสว่าง/มืดที่ผู้ใช้เลือก
enum NslModeChoice {
  system,
  light,
  dark;

  static NslModeChoice parse(Object? v) {
    for (final m in values) {
      if (m.name == v) return m;
    }
    return NslModeChoice.system;
  }

  ThemeMode get themeMode => switch (this) {
        NslModeChoice.system => ThemeMode.system,
        NslModeChoice.light => ThemeMode.light,
        NslModeChoice.dark => ThemeMode.dark,
      };
}

/// การปรับแต่งแบบ lite ที่ผู้ใช้ตั้งเองในแอป (ไม่ลึกเท่า NSL Palette): โหมด + accent
///
/// accent มาจาก preset ([presetId]) หรือสีกำหนดเอง ([customAccent]) อย่างใดอย่างหนึ่ง — ถ้ามีทั้งสอง preset ชนะ
/// ไม่ตั้งทั้งคู่ = ใช้ accent ของธีมตามเดิม ; ค่านี้ชนะ accent ในธีม (ธีมในตัว < ไฟล์ธีม < ค่า lite)
class NslAppearance {
  const NslAppearance({this.mode = NslModeChoice.system, this.presetId, this.customAccent});

  final NslModeChoice mode;
  final String? presetId;
  final Color? customAccent;

  static const none = NslAppearance();

  bool get hasAccent => presetId != null || customAccent != null;
  bool get isDefault => mode == NslModeChoice.system && !hasAccent;

  /// ชุดสี accent ของโหมดที่ต้องการ (null = ไม่ได้ตั้ง accent หรือ preset ที่อ้างไม่มีและไม่มีสีเอง)
  NslAccentSet? accentSet(bool dark, [List<NslAccentPreset> presets = kAccentPresets]) {
    final id = presetId;
    if (id != null) {
      final p = accentPresetById(id, presets);
      if (p != null) return p.set(dark);
    }
    final c = customAccent;
    return c == null ? null : accentTints(c, dark);
  }

  NslAppearance withMode(NslModeChoice m) => NslAppearance(mode: m, presetId: presetId, customAccent: customAccent);

  /// เลือก preset (ล้างสีเอง)
  NslAppearance withPreset(String id) => NslAppearance(mode: mode, presetId: id);

  /// เลือกสีเอง (ล้าง preset)
  NslAppearance withCustom(Color c) => NslAppearance(mode: mode, customAccent: c);

  /// ล้าง accent กลับไปใช้ของธีม (คงโหมดไว้)
  NslAppearance clearedAccent() => NslAppearance(mode: mode);

  Map<String, Object?> toJson() => {
        'mode': mode.name,
        if (presetId != null) 'preset': presetId,
        if (presetId == null && customAccent != null) 'customAccent': _hex(customAccent!),
      };

  /// อ่านแบบไม่โยน: ค่าที่ไม่รู้จัก/รูปแบบผิด = ข้าม
  static NslAppearance fromJson(Object? j) {
    if (j is! Map) return none;
    final preset = j['preset'];
    final custom = j['customAccent'];
    return NslAppearance(
      mode: NslModeChoice.parse(j['mode']),
      presetId: preset is String && _presetIdRe.hasMatch(preset) ? preset : null,
      customAccent: custom is String ? _parseHex(custom) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NslAppearance && mode == other.mode && presetId == other.presetId && customAccent == other.customAccent;

  @override
  int get hashCode => Object.hash(mode, presetId, customAccent);
}

final _presetIdRe = RegExp(r'^[a-z0-9][a-z0-9._-]{0,31}$');
final _hexRe = RegExp(r'^#[0-9a-fA-F]{6}$');

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Color? _parseHex(String s) => _hexRe.hasMatch(s) ? Color(0xFF000000 | int.parse(s.substring(1), radix: 16)) : null;
