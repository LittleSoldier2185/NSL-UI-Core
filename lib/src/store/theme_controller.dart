import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../appearance/appearance.dart';
import '../builtin/builtin_themes.dart';
import '../format/nslt_codec.dart';
import '../format/resolve.dart';
import '../format/theme_spec.dart';
import 'store_models.dart';
import 'theme_storage.dart';

/// ตัวกลางที่แอปฟัง: โหลดธีมจาก [NslThemeStorage], เลือกธีมที่ใช้, ดูการเปลี่ยนแปลงสด และมี safe mode
///
/// [activeSpec] เป็น null เสมอเมื่อ: safe mode, ไม่ได้เลือกธีม, ธีมที่เลือกหายไป, หรือใช้งานไม่ได้
/// (resolve ไม่ผ่านทั้งโหมดสว่าง/มืด) — แอปถอยไปธีมในตัวได้โดยไม่ต้องตรวจเอง เหตุผลอยู่ที่ [problems]
class NslThemeController extends ChangeNotifier {
  NslThemeController(this.store);
  final NslThemeStorage store;

  NslStoreSnapshot _snap = const NslStoreSnapshot();
  NslUiSettings _settings = const NslUiSettings();
  NslThemeSpec? _active;
  final List<String> _problems = [];
  StreamSubscription<void>? _sub;
  bool _disposed = false;

  NslUiSettings get settings => _settings;
  bool get safeMode => _settings.safeMode;
  NslThemeSpec? get activeSpec => _active;
  List<NslThemeSpec> get userThemes => _snap.themes.values.toList();
  List<String> get problems => List.unmodifiable(_problems);

  /// ค่า lite ของผู้ใช้ (โหมด + accent)
  NslAppearance get appearance => _settings.appearance;

  /// โหมดสว่าง/มืดที่ผู้ใช้เลือก (ใส่ `MaterialApp.themeMode`)
  ThemeMode get themeMode => _settings.appearance.mode.themeMode;

  /// ธีมที่แอปควรใช้จริง: ธีมผู้ใช้ที่เลือก (ถ้ามีและใช้ได้) ไม่งั้น [fallback] (ธีมในตัวของแอป)
  /// แล้วทับด้วยค่า lite ของผู้ใช้ — ลำดับ: ธีมในตัว < ไฟล์ธีม < ค่า lite ; safe mode = [fallback] ล้วน ๆ
  NslThemeSpec effective(NslThemeSpec fallback) {
    if (_settings.safeMode) return fallback;
    return (_active ?? fallback).withAppearance(_settings.appearance);
  }

  NslThemeSpec? lookup(String id) => _snap.themes[id] ?? builtinThemeById(id);

  Future<void> reload() async {
    final snap = await store.loadAll();
    final settings = await store.loadSettings();
    if (_disposed) return;
    _snap = snap;
    _settings = settings;
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    _problems
      ..clear()
      ..addAll(_snap.problems);
    _active = null;
    final id = _settings.activeThemeId;
    if (_settings.safeMode || id == null) return;
    final spec = _snap.themes[id];
    if (spec == null) {
      _problems.add('active theme "$id" not found');
      return;
    }
    try {
      for (final b in [Brightness.light, Brightness.dark]) {
        resolveTokens(spec, b, lookup: lookup);
      }
      _active = spec;
    } on NslResolveException catch (e) {
      _problems.add('theme "$id" unusable: ${e.message}');
    }
  }

  Future<void> select(String? id) async {
    _settings = _settings.copyWith(activeThemeId: id);
    await store.saveSettings(_settings);
    _recompute();
    notifyListeners();
  }

  /// ลบธีมของผู้ใช้ [id] ; ถ้าเป็นธีมที่เลือกใช้อยู่ = ล้างตัวเลือกก่อน (กลับไปธีมในตัวของแต่ละแอป) ; id สงวน/ผิดรูปแบบ/ไม่มีไฟล์ = ไม่ทำอะไร
  Future<void> deleteTheme(String id) async {
    if (!isValidThemeId(id) || isReservedThemeId(id)) return;
    if (_settings.activeThemeId == id) {
      _settings = _settings.copyWith(activeThemeId: null);
      await store.saveSettings(_settings);
    }
    await store.deleteTheme(id);
    await reload();
  }

  /// ตั้งค่า lite (โหมด + accent) แล้วเก็บลง `ui-settings.json`
  Future<void> setAppearance(NslAppearance a) async {
    _settings = _settings.copyWith(appearance: a);
    await store.saveSettings(_settings);
    notifyListeners();
  }

  /// นำเข้าธีมจากข้อความไฟล์ `.nslt` (Android/ทุกแพลตฟอร์ม: ผู้ใช้เลือกไฟล์แล้วแอปส่งข้อความเข้ามา)
  /// ปฏิเสธไฟล์ที่เสีย/ใหญ่เกิน/ใช้ id สงวน — ไม่โยน ผลอยู่ใน [NslImportResult] ; id ซ้ำ = แทนที่ของเดิม
  Future<NslImportResult> importThemeText(String text) async {
    final r = parseNslt(text);
    final spec = r.spec;
    if (spec == null) return NslImportResult(errors: r.errors);
    if (isReservedThemeId(spec.id)) {
      return NslImportResult(errors: ['id "${spec.id}" is reserved for built-in themes — rename it before importing']);
    }
    try {
      await store.saveTheme(spec);
    } on ArgumentError catch (e) {
      return NslImportResult(errors: ['cannot save: ${e.message}']);
    } catch (e) {
      return NslImportResult(errors: ['cannot save: ${e.runtimeType}']);
    }
    await reload();
    return NslImportResult(id: spec.id, warnings: r.warnings);
  }

  /// ข้อความไฟล์ `.nslt` ของธีมผู้ใช้ [id] สำหรับส่งออก (null ถ้าไม่มี) — ธีมในตัวส่งออกตรง ๆ ไม่ได้ (ทำสำเนาก่อน)
  String? exportThemeText(String id) {
    final spec = _snap.themes[id];
    return spec == null ? null : serializeNslt(spec);
  }

  Future<void> setSafeMode(bool on) async {
    _settings = _settings.copyWith(safeMode: on);
    await store.saveSettings(_settings);
    _recompute();
    notifyListeners();
  }

  /// เริ่มดูโฟลเดอร์: ไฟล์เปลี่ยนจากแอปอื่น (เช่น Theme Editor ใน NSL Dev) → โหลดใหม่และแจ้งผู้ฟัง
  void startWatching({Duration debounce = const Duration(milliseconds: 150)}) {
    _sub ??= store.watch(debounce: debounce).listen((_) => reload());
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}

/// ผลการนำเข้าธีม: สำเร็จเมื่อ [id] ไม่เป็น null
class NslImportResult {
  const NslImportResult({this.id, this.errors = const [], this.warnings = const []});
  final String? id;
  final List<String> errors;
  final List<String> warnings;
  bool get ok => id != null;
}
