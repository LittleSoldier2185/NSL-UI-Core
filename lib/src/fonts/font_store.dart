import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;

import '../tokens/style_tokens.dart';
import 'font_info.dart';

/// จำนวนไฟล์ฟอนต์ของผู้ใช้สูงสุดในโฟลเดอร์ และขนาดรวมสูงสุด (กันโฟลเดอร์บวม/ไฟล์จำนวนมากที่ทำให้เปิดแอปช้า)
const kMaxUserFonts = 64;
const kMaxUserFontsTotalBytes = 128 * 1024 * 1024;

/// ฟังก์ชันลงทะเบียนฟอนต์กับระบบ (ค่าเริ่มต้นใช้ `FontLoader` ของ Flutter ; เทสต์/แอปส่งตัวอื่นได้)
typedef NslFontRegistrar = Future<void> Function(String family, Uint8List bytes);

Future<void> _flutterRegister(String family, Uint8List bytes) async {
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// ฟอนต์ของผู้ใช้ที่ผ่านการตรวจแล้ว
class NslUserFont {
  const NslUserFont({required this.family, required this.fileName, required this.info});
  final String family;
  final String fileName;
  final NslFontInfo info;
}

class NslFontImportResult {
  const NslFontImportResult.ok(NslUserFont this.font) : error = null;
  const NslFontImportResult.failed(String this.error) : font = null;
  final NslUserFont? font;
  final String? error;
  bool get isOk => font != null;
}

/// ผลดูฟอนต์ที่ธีมระบุ : บทบาทไหนต้องวางฟอนต์ไทยก่อน และปัญหาที่ผู้ใช้ควรรู้ (ว่าง = ไม่มีปัญหา)
class NslFontReport {
  const NslFontReport({this.thaiFirst = const {}, this.issues = const {}});
  final Set<String> thaiFirst;
  final Map<String, List<NslFontIssue>> issues;
  bool get hasIssues => issues.values.any((l) => l.isNotEmpty);
}

/// ที่เก็บฟอนต์ที่ผู้ใช้นำเข้า (ตำแหน่งมาตรฐาน `Documents\NSL\Fonts` ; Android = โฟลเดอร์ส่วนตัวของแอป)
///
/// ทั้งไฟล์ที่นำเข้าและไฟล์ที่ผู้ใช้วางในโฟลเดอร์เองถือเป็นข้อมูลไม่น่าเชื่อถือ : อ่านเฉพาะไฟล์ปกติ `.ttf/.otf` (ไม่ตาม symlink),
/// ต้องผ่าน [inspectFontBytes], มีชื่อ family ที่อ่านได้และไม่ชนฟอนต์ที่ nsl_ui ใช้เป็นฟอนต์สำรอง ; ชื่อไฟล์ที่เขียนสร้างจากชื่อ family
/// (ไม่ใช้ชื่อที่ผู้ใช้/ไฟล์ให้มา) ; โหลดไม่ได้ = ข้ามไฟล์นั้น ธีมที่อ้างชื่อนั้นตกไปฟอนต์สำรองเงียบ ๆ
class NslFontStore {
  NslFontStore(this.dir, {NslFontRegistrar? register}) : _register = register ?? _flutterRegister;

  /// [documents] ต้องมาจากโฟลเดอร์ Documents ของระบบ (วิธีเดียวกับ `NslThemeStore.standard`)
  factory NslFontStore.standard({required Directory documents, NslFontRegistrar? register}) {
    final sep = Platform.pathSeparator;
    return NslFontStore(Directory('${documents.path}${sep}NSL${sep}Fonts'), register: register);
  }

  final Directory dir;
  final NslFontRegistrar _register;
  final Map<String, NslFontInfo> _infos = {};
  final Set<String> _registered = {};

  /// ฟอนต์ที่โหลดสำเร็จแล้ว (family → ผลตรวจ)
  Map<String, NslFontInfo> get infos => Map.unmodifiable(_infos);

  static final _reserved = {
    for (final f in [...kNslFontFallback, 'Noto Sans Thai']) f.split('/').last.toLowerCase(),
  };

  /// ชื่อ family ที่ห้ามใช้ (ชนฟอนต์สำรองของ nsl_ui — ผู้ใช้ทับฟอนต์สำรองไม่ได้)
  static bool isReservedFamily(String family) => _reserved.contains(family.toLowerCase());

  /// ชื่อไฟล์ที่เขียนจากชื่อ family (FNV-1a 32 บิต ไม่มีอักขระจากผู้ใช้เลย)
  static String _fileNameFor(String family, bool otf) {
    var h = 0x811C9DC5;
    for (final u in family.codeUnits) {
      h = ((h ^ (u & 0xFF)) * 0x01000193) & 0xFFFFFFFF;
      h = ((h ^ (u >> 8)) * 0x01000193) & 0xFFFFFFFF;
    }
    return 'font-${h.toRadixString(16).padLeft(8, '0')}.${otf ? 'otf' : 'ttf'}';
  }

  /// นำเข้าฟอนต์จาก [bytes] (แอปเป็นผู้เลือกไฟล์) : ตรวจ → เขียนแบบ atomic → ลงทะเบียน ; ฟอนต์ family เดิมถูกแทนที่
  Future<NslFontImportResult> importFont(Uint8List bytes) async {
    final r = inspectFontBytes(bytes);
    if (!r.isOk) return NslFontImportResult.failed(r.error!);
    final info = r.info!;
    final family = info.familyName;
    if (family == null) return const NslFontImportResult.failed('font has no readable family name');
    if (isReservedFamily(family)) return NslFontImportResult.failed('"$family" is reserved (built-in fallback font)');

    final existing = await _scan();
    final others = existing.fonts.where((f) => f.family != family).toList();
    if (others.length >= kMaxUserFonts) return const NslFontImportResult.failed('too many fonts — remove one first');
    final total = existing.totalBytes - (existing.sizes[family] ?? 0) + bytes.length;
    if (total > kMaxUserFontsTotalBytes) return const NslFontImportResult.failed('fonts take too much space — remove one first');

    final otf = bytes.length >= 4 && bytes[0] == 0x4F && bytes[1] == 0x54 && bytes[2] == 0x54 && bytes[3] == 0x4F;
    final name = _fileNameFor(family, otf);
    try {
      await dir.create(recursive: true);
      // ฟอนต์ family เดิมที่เป็นนามสกุลอื่น (ttf ↔ otf) ลบก่อน กันซ้ำ
      for (final f in existing.fonts.where((f) => f.family == family && f.fileName != name)) {
        await _deleteFile(f.fileName);
      }
      final sep = Platform.pathSeparator;
      final target = File('${dir.path}$sep$name');
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(target.path);
    } on FileSystemException catch (e) {
      return NslFontImportResult.failed('cannot save the font: ${e.message}');
    }
    final font = NslUserFont(family: family, fileName: name, info: info);
    await _registerOne(font, bytes);
    return NslFontImportResult.ok(font);
  }

  /// ฟอนต์ในโฟลเดอร์ที่ผ่านการตรวจ ; ไฟล์ที่ข้ามถูกบอกเหตุผลใน [problems]
  Future<List<NslUserFont>> list({List<String>? problems}) async {
    final s = await _scan(problems: problems);
    return s.fonts;
  }

  /// ลงทะเบียนฟอนต์ทั้งหมดในโฟลเดอร์ (เรียกตอนเปิดแอป) แล้วคืนรายการปัญหา — ไม่โยน exception
  Future<List<String>> loadAll() async {
    final problems = <String>[];
    final s = await _scan(problems: problems, keepBytes: true);
    for (final f in s.fonts) {
      await _registerOne(f, s.bytes[f.fileName]!, problems: problems);
    }
    return problems;
  }

  /// ลบฟอนต์ family นี้ออกจากโฟลเดอร์ (ที่ลงทะเบียนไปแล้วในรอบการทำงานนี้ยังใช้ได้จนปิดแอป — Flutter ถอนทะเบียนไม่ได้)
  Future<bool> remove(String family) async {
    final s = await _scan();
    var any = false;
    for (final f in s.fonts.where((f) => f.family == family)) {
      any = await _deleteFile(f.fileName) || any;
    }
    return any;
  }

  /// ดูฟอนต์ที่ [type] ระบุเทียบกับฟอนต์ที่โหลดแล้ว : บทบาทไหนต้องไทยก่อน + ปัญหา (เฉพาะฟอนต์ที่เป็นไฟล์ของผู้ใช้ ฟอนต์อื่นไม่ถูกตัดสิน)
  NslFontReport reportFor(NslType type) {
    final first = <String>{};
    final issues = <String, List<NslFontIssue>>{};
    void role(String name, String? latin, String? thai) {
      final plan = planFontOrder(latin: latin == null ? null : _infos[latin], thai: thai == null ? null : _infos[thai]);
      if (plan.thaiFirst) first.add(name);
      if (plan.issues.isNotEmpty) issues[name] = plan.issues;
    }

    role('family', type.family, type.familyThai);
    role('content', type.content, type.contentThai);
    role('mono', type.mono, type.monoThai);
    return NslFontReport(thaiFirst: first, issues: issues);
  }

  /// [type] ที่ตั้ง `thaiFirst` ตามผลการตรวจฟอนต์ที่โหลดแล้ว (ใช้ตอนสร้างธีม)
  NslType adapt(NslType type) {
    final r = reportFor(type);
    return r.thaiFirst.isEmpty && type.thaiFirst.isEmpty ? type : type.copyWith(thaiFirst: r.thaiFirst);
  }

  // ---------------------------------------------------------------------------

  Future<void> _registerOne(NslUserFont f, Uint8List bytes, {List<String>? problems}) async {
    if (_registered.contains(f.family)) {
      _infos[f.family] = f.info;
      return;
    }
    try {
      await _register(f.family, bytes);
      _registered.add(f.family);
      _infos[f.family] = f.info;
    } catch (e) {
      problems?.add('${f.fileName}: cannot be loaded as a font');
    }
  }

  Future<bool> _deleteFile(String name) async {
    try {
      final f = File('${dir.path}${Platform.pathSeparator}$name');
      if (await FileSystemEntity.type(f.path, followLinks: false) != FileSystemEntityType.file) return false;
      await f.delete();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  Future<_Scan> _scan({List<String>? problems, bool keepBytes = false}) async {
    final out = _Scan();
    if (!await dir.exists()) return out;
    final names = <String>[];
    try {
      await for (final e in dir.list(followLinks: false)) {
        final base = e.uri.pathSegments.isEmpty ? '' : e.uri.pathSegments.last;
        final lower = base.toLowerCase();
        if (!lower.endsWith('.ttf') && !lower.endsWith('.otf')) continue;
        if (await FileSystemEntity.type(e.path, followLinks: false) != FileSystemEntityType.file) {
          problems?.add('$base: not a regular file — skipped');
          continue;
        }
        names.add(base);
      }
    } on FileSystemException {
      problems?.add('cannot read the fonts folder');
      return out;
    }
    names.sort();
    for (final name in names) {
      if (out.fonts.length >= kMaxUserFonts) {
        problems?.add('$name: too many fonts — skipped');
        continue;
      }
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      try {
        final len = await file.length();
        if (len > kMaxFontBytes) {
          problems?.add('$name: font file too large — skipped');
          continue;
        }
        if (out.totalBytes + len > kMaxUserFontsTotalBytes) {
          problems?.add('$name: fonts take too much space — skipped');
          continue;
        }
        final bytes = await file.readAsBytes();
        final r = inspectFontBytes(bytes);
        if (!r.isOk) {
          problems?.add('$name: ${r.error}');
          continue;
        }
        final family = r.info!.familyName;
        if (family == null) {
          problems?.add('$name: no readable family name — skipped');
          continue;
        }
        if (isReservedFamily(family)) {
          problems?.add('$name: "$family" is reserved — skipped');
          continue;
        }
        if (out.sizes.containsKey(family)) {
          problems?.add('$name: "$family" is already provided by another file — skipped');
          continue;
        }
        out.fonts.add(NslUserFont(family: family, fileName: name, info: r.info!));
        out.sizes[family] = len;
        out.totalBytes += len;
        if (keepBytes) out.bytes[name] = bytes;
      } on FileSystemException {
        problems?.add('$name: cannot be read — skipped');
      }
    }
    return out;
  }
}

class _Scan {
  final fonts = <NslUserFont>[];
  final sizes = <String, int>{};
  final bytes = <String, Uint8List>{};
  int totalBytes = 0;
}
