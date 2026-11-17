import 'dart:async';

import '../format/theme_spec.dart';
import 'store_models.dart';

/// ที่เก็บธีมและค่าตั้ง UI — แยกเป็น interface เพื่อให้แต่ละแพลตฟอร์มมีวิธีของตัวเอง
/// - Windows: [NslThemeStore.standard] — ไฟล์ธีมที่ `Documents\NSL\Themes` (แชร์ข้ามแอปและ NSL Launcher + watcher), ค่าตั้งที่ `%APPDATA%\NSL`
/// - Android: [NslThemeStore] ชี้ไปโฟลเดอร์ส่วนตัวของแอป (แชร์ข้ามแอปไม่ได้ และไม่มี Launcher — ผู้ใช้นำเข้าไฟล์ในแต่ละแอป)
/// - ไม่มีดิสก์/ทดสอบ: [NslMemoryThemeStorage]
abstract interface class NslThemeStorage {
  Future<NslStoreSnapshot> loadAll();
  Future<NslUiSettings> loadSettings();
  Future<void> saveSettings(NslUiSettings s);

  /// บันทึกธีม (id ต้องใช้ได้และไม่สงวน มิฉะนั้นโยน [ArgumentError])
  Future<void> saveTheme(NslThemeSpec spec);
  Future<void> deleteTheme(String id);

  /// เหตุการณ์เปลี่ยนแปลงจากภายนอก (ที่เก็บที่ไม่มีการแชร์ส่งสตรีมว่าง)
  Stream<void> watch({Duration debounce});
}

/// ที่เก็บในหน่วยความจำ (ไม่แชร์ข้ามโปรเซส ไม่มีดิสก์) — ใช้ในเทสต์หรือแอปที่ยังไม่ต้องการเก็บถาวร
class NslMemoryThemeStorage implements NslThemeStorage {
  final Map<String, NslThemeSpec> _themes = {};
  NslUiSettings _settings = const NslUiSettings();

  @override
  Future<NslStoreSnapshot> loadAll() async => NslStoreSnapshot(themes: Map.of(_themes));

  @override
  Future<NslUiSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(NslUiSettings s) async => _settings = s;

  @override
  Future<void> saveTheme(NslThemeSpec spec) async {
    if (!isValidThemeId(spec.id) || isReservedThemeId(spec.id)) {
      throw ArgumentError.value(spec.id, 'spec.id', 'invalid or reserved theme id');
    }
    _themes[spec.id] = spec;
  }

  @override
  Future<void> deleteTheme(String id) async => _themes.remove(id);

  @override
  Stream<void> watch({Duration debounce = const Duration(milliseconds: 150)}) => const Stream.empty();
}
