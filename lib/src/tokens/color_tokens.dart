import 'dart:ui';

/// ชื่อ token สี core ทั้งหมด (ลำดับนี้ใช้ตอนเขียนไฟล์ด้วย)
const kCoreColorKeys = <String>[
  'bg',
  'chrome',
  'surface',
  'surfaceRaised',
  'surfaceSunken',
  'borderSoft',
  'border',
  'borderStrong',
  'text',
  'textMuted',
  'textFaint',
  'icon',
  'accent',
  'accentInk',
  'accentTint',
  'onAccent',
  'hover',
  'selected',
  'accentBorder',
  'danger',
  'dangerBg',
  'dangerText',
  'warnBg',
  'warnText',
  'infoBg',
  'infoText',
  'success',
  'successBg',
  'successText',
  'shadow',
];

/// สี core ที่ resolve ครบแล้ว (ทุก token มีค่าเสมอ)
///
/// สร้างผ่าน `resolveColors` (derive/สืบทอดค่าที่ไม่ได้ระบุ) หรือ [NslColors.fromMap] เมื่อมีครบทุกคีย์
class NslColors {
  NslColors.fromMap(Map<String, Color> values) : _v = Map.unmodifiable(values) {
    for (final k in kCoreColorKeys) {
      if (!values.containsKey(k)) {
        throw ArgumentError('NslColors: missing "$k"');
      }
    }
  }

  final Map<String, Color> _v;

  /// ค่าทั้งหมดตามชื่อ (อ่านอย่างเดียว)
  Map<String, Color> toMap() => _v;

  Color operator [](String key) => _v[key]!;

  Color get bg => _v['bg']!;
  Color get chrome => _v['chrome']!;
  Color get surface => _v['surface']!;
  Color get surfaceRaised => _v['surfaceRaised']!;
  Color get surfaceSunken => _v['surfaceSunken']!;
  Color get borderSoft => _v['borderSoft']!;
  Color get border => _v['border']!;
  Color get borderStrong => _v['borderStrong']!;
  Color get text => _v['text']!;
  Color get textMuted => _v['textMuted']!;
  Color get textFaint => _v['textFaint']!;
  Color get icon => _v['icon']!;
  Color get accent => _v['accent']!;
  Color get accentInk => _v['accentInk']!;
  Color get accentTint => _v['accentTint']!;
  Color get onAccent => _v['onAccent']!;
  Color get hover => _v['hover']!;
  Color get selected => _v['selected']!;
  Color get accentBorder => _v['accentBorder']!;
  Color get danger => _v['danger']!;
  Color get dangerBg => _v['dangerBg']!;
  Color get dangerText => _v['dangerText']!;
  Color get warnBg => _v['warnBg']!;
  Color get warnText => _v['warnText']!;
  Color get infoBg => _v['infoBg']!;
  Color get infoText => _v['infoText']!;
  Color get success => _v['success']!;
  Color get successBg => _v['successBg']!;
  Color get successText => _v['successText']!;
  Color get shadow => _v['shadow']!;

  @override
  bool operator ==(Object other) {
    if (other is! NslColors) return false;
    for (final k in kCoreColorKeys) {
      if (_v[k] != other._v[k]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(kCoreColorKeys.map((k) => _v[k]));
}
