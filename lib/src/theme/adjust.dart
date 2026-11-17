import 'package:flutter/material.dart';

import '../tokens/nsl_tokens.dart';
import '../tokens/style_tokens.dart';

/// ขนาดขั้นต่ำของพื้นที่แตะบนจอสัมผัส (dp)
const kMinTapTarget = 44.0;

/// ตัวช่วยแปลง token รูปทรง/ความหนาแน่น/ขนาดตัวอักษร เป็นค่าที่ใช้ปรับ ThemeData ของแอป
///
/// ออกแบบเป็น "ตัวคูณจากค่าเริ่มต้น" เพื่อให้ธีมที่ไม่ได้แตะค่าเหล่านี้ได้ผลเท่าเดิมทุกพิกเซล (parity)
/// แอปที่มีรัศมีเฉพาะตัว (เช่น dialog โค้ง 14) จึงคงสัดส่วนของตัวเองไว้ได้ แล้วขยับตามธีม
extension NslTokenAdjust on NslTokens {
  /// ตัวคูณมุมโค้ง = `shape.md` ของธีม ÷ ค่าเริ่มต้น (1.0 เมื่อไม่ได้ปรับ)
  double get radiusFactor => shape.md / const NslShape().md;

  /// รัศมีที่แอปใช้เดิมเท่า [base] → ค่าที่ปรับตามธีมแล้ว (ไม่เกินขอบเขตของ [NslShape])
  double radius(double base) => (base * radiusFactor).clamp(NslShape.minRadius, NslShape.maxRadius).toDouble();

  BorderRadius borderRadius(double base) => BorderRadius.circular(radius(base));

  /// ความหนาแน่นสำหรับ Material controls (ไม่รวมแคนวาส)
  VisualDensity get visualDensity => switch (density) {
        NslDensity.compact => const VisualDensity(horizontal: -2, vertical: -2),
        NslDensity.normal => VisualDensity.standard,
        NslDensity.comfortable => const VisualDensity(horizontal: 1, vertical: 1),
      };

  /// เหมือน [visualDensity] แต่บนจอสัมผัส ([touch] = true) `compact` ถูกยกเป็น `normal`
  /// เพื่อไม่ให้ปุ่มเล็กกว่าขนาดที่นิ้วแตะได้ ([kMinTapTarget])
  VisualDensity visualDensityFor({bool touch = false}) =>
      touch && density == NslDensity.compact ? VisualDensity.standard : visualDensity;

  /// ตัวคูณขนาดตัวอักษรของ UI (แคนวาสไม่ใช้ตัวนี้)
  double get fontSizeFactor => type.scale;
}

/// ขยาย/ย่อขนาดตัวอักษรทุกสไตล์ใน [t] ด้วย [factor] — ข้ามสไตล์ที่ไม่ระบุขนาด (TextTheme.apply จะ assert ในกรณีนี้)
TextTheme scaleTextTheme(TextTheme t, double factor) {
  if (factor == 1.0) return t;
  TextStyle? s(TextStyle? x) => x?.fontSize == null ? x : x!.copyWith(fontSize: x.fontSize! * factor);
  return t.copyWith(
    displayLarge: s(t.displayLarge), displayMedium: s(t.displayMedium), displaySmall: s(t.displaySmall),
    headlineLarge: s(t.headlineLarge), headlineMedium: s(t.headlineMedium), headlineSmall: s(t.headlineSmall),
    titleLarge: s(t.titleLarge), titleMedium: s(t.titleMedium), titleSmall: s(t.titleSmall),
    bodyLarge: s(t.bodyLarge), bodyMedium: s(t.bodyMedium), bodySmall: s(t.bodySmall),
    labelLarge: s(t.labelLarge), labelMedium: s(t.labelMedium), labelSmall: s(t.labelSmall),
  );
}

/// textTheme ที่ขยายขนาดตามธีม : `ThemeData.textTheme` ยังไม่มีขนาดจนกว่า MaterialApp จะ localize
/// จึงเติมขนาดมาตรฐาน (Material 2021) ก่อนค่อยคูณ — [current] คือสไตล์ที่แอปตั้งไว้ (สี/ฟอนต์) ซ้อนทับ
TextTheme scaledTextTheme(Brightness b, TextTheme current, double factor) {
  if (factor == 1.0) return current;
  final typo = Typography.material2021(platform: TargetPlatform.windows);
  final defaults = (b == Brightness.dark ? typo.white : typo.black).merge(typo.englishLike);
  return scaleTextTheme(defaults.merge(current), factor);
}
