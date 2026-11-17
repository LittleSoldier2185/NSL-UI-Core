import 'dart:ui';

import '../appearance/appearance.dart';
import '../tokens/style_tokens.dart';

/// เวอร์ชัน schema สูงสุดที่ nsl_ui รุ่นนี้เข้าใจ (จำนวนเต็ม — เปลี่ยนเฉพาะเมื่อโครงสร้างไฟล์แตกหัก)
const kNsltSchema = 1;

/// เวอร์ชันของ core (UI Core) รุ่นนี้ — minor เพิ่ม token ได้อย่างเดียว ห้ามลบ/เปลี่ยนความหมายคีย์เดิม
/// ไฟล์ธีมที่บันทึกจากรุ่นนี้จะระบุ `core` ตามค่านี้
const kNslCoreVersion = '1.1';

/// สีที่ระบุไว้ในไฟล์ของหนึ่งโหมด (ระบุบางส่วนได้ — ที่เหลือสืบทอด/derive)
///
/// คีย์ที่ไม่รู้จักถูกเก็บไว้ด้วย เพื่อเขียนกลับครบเมื่อบันทึก (รุ่นเก่าไม่ทำของรุ่นใหม่หาย)
class NslModeSpec {
  const NslModeSpec({this.colors = const {}, this.extensions = const {}});

  final Map<String, Color> colors;
  final Map<String, Map<String, Color>> extensions;

  bool get isEmpty => colors.isEmpty && extensions.isEmpty;
}

/// เนื้อหาของไฟล์ `.nslt` ตามที่เขียนไว้ (ยังไม่ resolve)
class NslThemeSpec {
  const NslThemeSpec({
    required this.id,
    required this.name,
    this.schema = kNsltSchema,
    this.core,
    this.extendsId,
    this.light = const NslModeSpec(),
    this.dark = const NslModeSpec(),
    this.radius = const {},
    this.family,
    this.content,
    this.mono,
    this.minSize,
    this.scale,
    this.density,
    this.elevationMode,
    this.elevationStrength,
    this.apps = const [],
    this.unknown = const {},
    this.appearance,
  });

  final int schema;

  /// เวอร์ชัน core ที่สร้างไฟล์นี้ (เช่น "1.0") — null = ไม่ระบุ (ธีมในตัว/ไฟล์เก่า)
  final String? core;
  final String id;
  final String name;

  /// id ของธีมฐานที่สืบทอดค่ามา (null = ไม่สืบทอด ต้องระบุสี root ครบเอง)
  final String? extendsId;

  final NslModeSpec light, dark;

  /// แอปที่ธีมนี้ออกแบบมาให้ (เช่น `orbit`, `lyra`) — **คำใบ้สำหรับจัดหมวด/กรองรายการเท่านั้น ไม่จำกัดการใช้งาน** ; ว่าง = ใช้ได้กับทุกแอป
  /// ไม่สืบทอดจากธีมฐาน ; id ที่ไม่รู้จัก (แอปใหม่ในอนาคต) เก็บไว้
  final List<String> apps;

  /// ธีมนี้เหมาะกับแอป [appId] หรือไม่ (ไม่ระบุ `apps` = เหมาะกับทุกแอป)
  bool targets(String appId) => apps.isEmpty || apps.contains(appId);

  /// มุมโค้งที่ระบุ (เฉพาะคีย์ที่ระบุ)
  final Map<String, double> radius;

  /// ฟอนต์สามบทบาท: `family` = UI, `content` = เนื้อหา/อ่านยาว (เช่น serif), `mono`
  final String? family, content, mono;

  /// ขนาดตัวอักษรขั้นต่ำของ UI (หลังคูณ scale)
  final double? minSize;
  final double? scale;
  final NslDensity? density;
  final NslElevationMode? elevationMode;
  final double? elevationStrength;

  /// คีย์ระดับบนสุดที่รุ่นนี้ไม่รู้จัก (เก็บไว้เขียนกลับ)
  final Map<String, Object?> unknown;

  /// ค่า lite ของผู้ใช้ (ใช้ตอน resolve เท่านั้น — **ไม่เขียนลงไฟล์**) ชนะ accent ของธีม ดู [withAppearance]
  final NslAppearance? appearance;

  NslModeSpec mode(Brightness b) => b == Brightness.light ? light : dark;

  /// สำเนาที่ติดค่า lite ของผู้ใช้ไว้ ([a] = null หรือ default ล้างค่า) — ไม่แก้ตัวเดิม
  NslThemeSpec withAppearance(NslAppearance? a) => NslThemeSpec(
        id: id,
        name: name,
        schema: schema,
        core: core,
        extendsId: extendsId,
        light: light,
        dark: dark,
        radius: radius,
        family: family,
        content: content,
        mono: mono,
        minSize: minSize,
        scale: scale,
        density: density,
        elevationMode: elevationMode,
        elevationStrength: elevationStrength,
        apps: apps,
        unknown: unknown,
        appearance: (a == null || !a.hasAccent) ? null : a,
      );

  /// สำเนาที่เปลี่ยน id/ชื่อ/ธีมฐาน (ใช้ตอนทำสำเนาธีม) — ล้างค่า lite
  NslThemeSpec copyIdentity({String? id, String? name, String? extendsId, String? core}) => NslThemeSpec(
        id: id ?? this.id,
        name: name ?? this.name,
        schema: schema,
        core: core ?? this.core,
        extendsId: extendsId ?? this.extendsId,
        light: light,
        dark: dark,
        radius: radius,
        family: family,
        content: content,
        mono: mono,
        minSize: minSize,
        scale: scale,
        density: density,
        elevationMode: elevationMode,
        elevationStrength: elevationStrength,
        apps: apps,
        unknown: unknown,
      );
}
