import 'dart:convert';

import '../appearance/appearance.dart';
import '../format/theme_spec.dart';

/// ผลการอ่านโฟลเดอร์ธีม: ธีมที่ใช้ได้ + รายการปัญหา (ไฟล์ที่ข้าม พร้อมเหตุผล)
class NslStoreSnapshot {
  const NslStoreSnapshot({this.themes = const {}, this.problems = const []});
  final Map<String, NslThemeSpec> themes;
  final List<String> problems;
}

const _keep = Object();

/// การตั้งค่า UI ที่ใช้ร่วมกันทุกแอป (`ui-settings.json`)
class NslUiSettings {
  const NslUiSettings({this.activeThemeId, this.safeMode = false, this.appearance = NslAppearance.none});
  final String? activeThemeId;

  /// เปิด = ไม่ใช้ธีมผู้ใช้เลย (ใช้ธีมในตัว) — ทางกู้เมื่อธีมทำให้ใช้งานไม่ได้
  final bool safeMode;

  /// ค่า lite ของผู้ใช้ (โหมด + accent) — ใช้ร่วมทุกแอป ชนะ accent ของธีม
  final NslAppearance appearance;

  NslUiSettings copyWith({Object? activeThemeId = _keep, bool? safeMode, NslAppearance? appearance}) => NslUiSettings(
        activeThemeId: identical(activeThemeId, _keep) ? this.activeThemeId : activeThemeId as String?,
        safeMode: safeMode ?? this.safeMode,
        appearance: appearance ?? this.appearance,
      );

  /// อ่านแบบไม่โยน: ไฟล์เสีย/ใหญ่เกิน = ค่าเริ่มต้น
  static NslUiSettings parse(String source) {
    try {
      if (utf8.encode(source).length > 4096) return const NslUiSettings();
      final j = jsonDecode(source);
      if (j is! Map) return const NslUiSettings();
      final id = j['activeThemeId'];
      return NslUiSettings(
        activeThemeId: id is String && isValidThemeId(id) ? id : null,
        safeMode: j['safeMode'] == true,
        appearance: NslAppearance.fromJson(j['appearance']),
      );
    } catch (_) {
      return const NslUiSettings();
    }
  }

  String toJson() => const JsonEncoder.withIndent('  ').convert({
        'schema': 1,
        if (activeThemeId != null) 'activeThemeId': activeThemeId,
        'safeMode': safeMode,
        if (!appearance.isDefault) 'appearance': appearance.toJson(),
      });
}

final _idRe = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');

/// id ธีมที่ใช้เป็นชื่อไฟล์ได้อย่างปลอดภัย (ไม่มี path separator)
bool isValidThemeId(String id) => _idRe.hasMatch(id);

/// id ที่สงวนไว้สำหรับธีมในตัว — ไฟล์ผู้ใช้ใช้ไม่ได้
bool isReservedThemeId(String id) => id.startsWith('nsl.');

