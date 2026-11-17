/// ฟอนต์สำรองต่อท้ายเสมอ (ปิดท้ายด้วย Noto Sans Thai ที่แพ็กมากับ nsl_ui เพื่อให้ภาษาไทยแสดงถูกต้องทุกเครื่อง)
const kNslFontFallback = <String>[
  'packages/nsl_ui/Noto Sans Thai',
  'Leelawadee UI',
  'Segoe UI Symbol',
  'Segoe UI',
  'Tahoma',
];

/// ชื่อฟอนต์ Noto Sans Thai ที่แพ็กมากับ nsl_ui
const kNslThaiFont = 'packages/nsl_ui/Noto Sans Thai';

/// รูปทรง: มุมโค้งเป็นบันได (ค่าเริ่มต้นสอดคล้องกับค่าที่ทั้งสองแอปใช้จริง)
class NslShape {
  const NslShape({
    this.xs = 4,
    this.sm = 6,
    this.md = 8,
    this.lg = 12,
    this.xl = 16,
    this.pill = 999,
  });

  final double xs, sm, md, lg, xl, pill;

  static const keys = <String>['xs', 'sm', 'md', 'lg', 'xl', 'pill'];

  /// ช่วงค่าที่ยอมรับของแต่ละช่อง
  static const double minRadius = 0, maxRadius = 999;

  double operator [](String k) => switch (k) {
        'xs' => xs,
        'sm' => sm,
        'md' => md,
        'lg' => lg,
        'xl' => xl,
        'pill' => pill,
        _ => throw ArgumentError('NslShape: unknown "$k"'),
      };

  NslShape withValues(Map<String, double> o) => NslShape(
        xs: o['xs'] ?? xs,
        sm: o['sm'] ?? sm,
        md: o['md'] ?? md,
        lg: o['lg'] ?? lg,
        xl: o['xl'] ?? xl,
        pill: o['pill'] ?? pill,
      );

  Map<String, double> toMap() => {for (final k in keys) k: this[k]};

  @override
  bool operator ==(Object other) =>
      other is NslShape && xs == other.xs && sm == other.sm && md == other.md && lg == other.lg && xl == other.xl && pill == other.pill;

  @override
  int get hashCode => Object.hash(xs, sm, md, lg, xl, pill);
}

/// ตัวอักษร: ฟอนต์สามบทบาท (UI / เนื้อหา / mono) และสัดส่วนขนาดของ UI (ไม่รวมตัวหนังสือบนแคนวาส)
///
/// ธีมระบุได้แค่ "ชื่อ family" — แอปเป็นผู้จัดหาไฟล์ฟอนต์จริงเอง (nsl_ui ฝังเฉพาะ Noto Sans Thai)
class NslType {
  const NslType({
    this.family,
    this.content,
    this.mono,
    this.familyThai,
    this.contentThai,
    this.monoThai,
    this.thaiFirst = const {},
    this.scale = 1.0,
    this.minSize,
  });

  /// ฟอนต์ UI (ละติน/หลัก) ; null = ใช้ Noto Sans Thai ของ nsl_ui
  final String? family;

  /// ฟอนต์เนื้อหา/อ่านยาว (เช่น serif ของแอปเขียนนิยาย) ; null = ใช้ฟอนต์ UI
  final String? content;
  final String? mono;

  /// ฟอนต์ของอักษรไทยแยกตามบทบาท (core 1.2) ; null = ไม่แยก (อักษรไทยตกไปที่ฟอนต์สำรองเดิมที่ลงท้ายด้วย Noto Sans Thai)
  final String? familyThai, contentThai, monoThai;

  /// บทบาท (`family`/`content`/`mono`) ที่ต้องวางฟอนต์ไทยไว้ก่อน — ค่าจากการตรวจ cmap ตอนรัน (ดู `planFontOrder`) ไม่เขียนลงไฟล์ธีม
  /// ใช้เมื่อฟอนต์ละตินมีอักษรไทยด้วยแต่ฟอนต์ไทยไม่มีอักษรละติน : วางฟอนต์ไทยก่อน อักษรไทยจึงได้ฟอนต์ไทย ส่วนละตินตกลงมาที่ฟอนต์ละติน
  final Set<String> thaiFirst;
  final double scale;

  /// ขนาดตัวอักษรขั้นต่ำของ UI (หลังคูณ [scale]) ; null = ไม่มีขั้นต่ำ
  final double? minSize;

  static const double minScale = 0.9, maxScale = 1.2;
  static const double minMinSize = 8, maxMinSize = 16;

  /// ฟอนต์หลักของบทบาท : ถ้ามีเฉพาะช่องไทย (ช่องละตินว่าง) หรือถูกจัดให้ไทยก่อน → ฟอนต์ไทย (ไม่งั้น Noto ซึ่งมีอักษรไทยอยู่แล้วจะบังฟอนต์ไทยที่ผู้ใช้เลือก)
  String _primary(String role, String? latin, String? thai) {
    if (thai != null && (latin == null || thaiFirst.contains(role))) return thai;
    return latin ?? kNslThaiFont;
  }

  List<String> _chain(String primary, String? latin, String? thai) {
    final out = <String>[];
    for (final f in [latin, thai, ...kNslFontFallback]) {
      if (f != null && f != primary && !out.contains(f)) out.add(f);
    }
    return out;
  }

  /// ฟอนต์หลักที่ใช้จริง
  String get effectiveFamily => _primary('family', family, familyThai);

  /// ฟอนต์เนื้อหาที่ใช้จริง (ไม่ระบุ = ฟอนต์ UI)
  String get effectiveContent => content == null && contentThai == null ? effectiveFamily : _primary('content', content ?? family, contentThai);

  /// ลำดับฟอนต์สำรองของฟอนต์ UI (ไม่ซ้ำกับฟอนต์หลัก ; ฟอนต์ไทย/ละตินอีกช่องมาก่อน แล้วปิดท้ายด้วย Noto Sans Thai เสมอ)
  List<String> get fallback => _chain(effectiveFamily, family, familyThai);

  /// ลำดับฟอนต์สำรองของฟอนต์เนื้อหา
  List<String> get contentFallback => content == null && contentThai == null ? fallback : _chain(effectiveContent, content ?? family, contentThai);

  /// ขนาดที่ใช้จริงของขนาดฐาน [base] : คูณ [scale] แล้วไม่ต่ำกว่า [minSize]
  double fit(double base) {
    final v = base * scale;
    final m = minSize;
    return m != null && v < m ? m : v;
  }

  NslType copyWith({
    String? family,
    String? content,
    String? mono,
    String? familyThai,
    String? contentThai,
    String? monoThai,
    Set<String>? thaiFirst,
    double? scale,
    double? minSize,
  }) =>
      NslType(
        family: family ?? this.family,
        content: content ?? this.content,
        mono: mono ?? this.mono,
        familyThai: familyThai ?? this.familyThai,
        contentThai: contentThai ?? this.contentThai,
        monoThai: monoThai ?? this.monoThai,
        thaiFirst: thaiFirst ?? this.thaiFirst,
        scale: scale ?? this.scale,
        minSize: minSize ?? this.minSize,
      );

  @override
  bool operator ==(Object other) =>
      other is NslType &&
      family == other.family &&
      content == other.content &&
      mono == other.mono &&
      familyThai == other.familyThai &&
      contentThai == other.contentThai &&
      monoThai == other.monoThai &&
      _setEq(thaiFirst, other.thaiFirst) &&
      scale == other.scale &&
      minSize == other.minSize;

  @override
  int get hashCode => Object.hash(family, content, mono, familyThai, contentThai, monoThai, Object.hashAllUnordered(thaiFirst), scale, minSize);
}

bool _setEq(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

/// ความหนาแน่นของ UI (มีผลกับ widget ของ nsl_ui และ Material controls เท่านั้น ไม่รวมแคนวาส)
enum NslDensity {
  compact,
  normal,
  comfortable;

  static NslDensity? parse(Object? v) {
    for (final d in values) {
      if (d.name == v) return d;
    }
    return null;
  }
}

/// ความสูงของเงา
enum NslElevationMode {
  shadow,

  /// ไม่ใช้เงา ใช้เส้นขอบแทน
  flat;

  static NslElevationMode? parse(Object? v) {
    for (final m in values) {
      if (m.name == v) return m;
    }
    return null;
  }
}

class NslElevation {
  const NslElevation({this.mode = NslElevationMode.shadow, this.strength = 1.0});

  final NslElevationMode mode;

  /// ตัวคูณความเข้มเงา
  final double strength;

  static const double minStrength = 0, maxStrength = 1.5;

  @override
  bool operator ==(Object other) => other is NslElevation && mode == other.mode && strength == other.strength;

  @override
  int get hashCode => Object.hash(mode, strength);
}
