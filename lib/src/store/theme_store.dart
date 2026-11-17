import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../format/nslt_codec.dart';
import '../format/theme_spec.dart';
import 'store_models.dart';
import 'theme_storage.dart';

/// ที่เก็บธีมกลางบนดิสก์ — แยกเป็นสองส่วน:
/// - **ไฟล์ธีม** (`*.nslt` ที่ผู้ใช้เปิดดู/ส่งต่อ/สำรองเองได้): ตำแหน่งมาตรฐานคือ `Documents\NSL\Themes` ([NslThemeStore.standard])
/// - **ค่าตั้งภายใน** (`ui-settings.json`: ธีมที่เลือก, safe mode, ค่า lite): `<root>` (มาตรฐาน `%APPDATA%\NSL`) — เป็นค่าของเครื่อง ไม่ใช่ของที่ผู้ใช้ควรเห็น
///
/// ทุกแอปและ NSL Launcher ใช้ตำแหน่งเดียวกัน (Launcher เป็นแค่ผู้เขียนไฟล์อีกตัว) ; Android ไม่แชร์ข้ามแอป จึงใช้โฟลเดอร์ส่วนตัวของแอป
/// ผ่านตัวสร้างหลัก `NslThemeStore(dir)` (ไฟล์ธีมอยู่ `<dir>/themes`) แล้วนำเข้าไฟล์ผ่านตัวควบคุม
///
/// ไฟล์ในโฟลเดอร์ถือเป็นข้อมูลไม่น่าเชื่อถือ: อ่านเฉพาะไฟล์ปกติ (ไม่ตาม symlink), ขนาดไม่เกิน [kNsltMaxBytes],
/// ผ่าน [parseNslt] เท่านั้น, ห้ามใช้ id ที่สงวน, ชื่อไฟล์ต้องตรงกับ id ในไฟล์
const _knownSettingsKeys = {'schema', 'activeThemeId', 'safeMode', 'appearance'};

class NslThemeStore implements NslThemeStorage {
  /// [root] = ที่เก็บค่าตั้ง (`ui-settings.json`) ; ไฟล์ธีมอยู่ที่ [themes] (ไม่ระบุ = `<root>/themes` แบบเดิม — ใช้บน Android และในเทสต์)
  NslThemeStore(this.root, {Directory? themes}) : themesDir = themes ?? Directory('${root.path}${Platform.pathSeparator}themes');

  /// ตำแหน่งมาตรฐานบนเดสก์ท็อป: ไฟล์ธีมที่ `<documents>/NSL/Themes` ; ค่าตั้งที่ [settingsRoot] (ไม่ระบุ = [defaultRoot] ถ้าไม่มี = `<documents>/NSL`)
  ///
  /// [documents] ต้องมาจากโฟลเดอร์ Documents ของระบบ (เช่น `getApplicationDocumentsDirectory()` ของ path_provider ซึ่งบน Windows
  /// อ่านจาก Known Folder จึงตามการย้ายโฟลเดอร์/OneDrive ได้) — **ทุกแอปต้องหาจากวิธีเดียวกัน** ไม่งั้นจะเห็นโฟลเดอร์คนละที่ แล้วแชร์ธีมกันไม่ได้
  factory NslThemeStore.standard({required Directory documents, Directory? settingsRoot, Map<String, String>? env}) {
    final sep = Platform.pathSeparator;
    final nsl = '${documents.path}${sep}NSL';
    return NslThemeStore(settingsRoot ?? defaultRoot(env) ?? Directory(nsl), themes: Directory('$nsl${sep}Themes'));
  }

  final Directory root;

  /// โฟลเดอร์ไฟล์ธีม
  final Directory themesDir;

  /// `%APPDATA%\NSL` บน Windows (null ถ้าหาไม่ได้) — ที่เก็บ**ค่าตั้ง** (ไม่ใช่ไฟล์ธีม) ; เทสต์ใช้โฟลเดอร์ชั่วคราวแทน
  static Directory? defaultRoot([Map<String, String>? env]) {
    final e = env ?? Platform.environment;
    final base = Platform.isWindows ? e['APPDATA'] : e['XDG_CONFIG_HOME'] ?? (e['HOME'] == null ? null : '${e['HOME']}/.config');
    if (base == null || base.isEmpty) return null;
    return Directory('$base${Platform.pathSeparator}NSL');
  }

  File get settingsFile => File('${root.path}${Platform.pathSeparator}ui-settings.json');
  File _fileFor(String id) => File('${themesDir.path}${Platform.pathSeparator}$id.nslt');

  @override
  Future<NslStoreSnapshot> loadAll() async {
    final themes = <String, NslThemeSpec>{};
    final problems = <String>[];
    if (!await themesDir.exists()) return const NslStoreSnapshot();
    final files = <File>[];
    try {
      await for (final e in themesDir.list(followLinks: false)) {
        if (e is File && e.path.toLowerCase().endsWith('.nslt')) files.add(e);
      }
    } on FileSystemException catch (e) {
      return NslStoreSnapshot(problems: ['cannot list themes: ${e.message}']);
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      try {
        if (await FileSystemEntity.type(f.path, followLinks: false) != FileSystemEntityType.file) {
          problems.add('$name: not a regular file');
          continue;
        }
        if (await f.length() > kNsltMaxBytes) {
          problems.add('$name: file too large');
          continue;
        }
        final r = parseNslt(utf8.decode(await f.readAsBytes(), allowMalformed: true));
        final spec = r.spec;
        if (spec == null) {
          problems.add('$name: ${r.errors.join('; ')}');
          continue;
        }
        if (isReservedThemeId(spec.id)) {
          problems.add('$name: id "${spec.id}" is reserved');
          continue;
        }
        if (name.substring(0, name.length - 5) != spec.id) {
          problems.add('$name: file name does not match id "${spec.id}"');
          continue;
        }
        themes[spec.id] = spec;
      } on FileSystemException catch (e) {
        problems.add('$name: ${e.message}');
      }
    }
    return NslStoreSnapshot(themes: themes, problems: problems);
  }

  @override
  Future<NslUiSettings> loadSettings() async {
    try {
      if (!await settingsFile.exists() || await settingsFile.length() > 4096) return const NslUiSettings();
      return NslUiSettings.parse(await settingsFile.readAsString());
    } on FileSystemException {
      return const NslUiSettings();
    }
  }

  /// เก็บค่าตั้ง โดย **คงคีย์ที่รุ่นนี้ไม่รู้จักไว้** (เช่น คีย์ใหม่ของ core รุ่นหลัง/แอปอื่น) — ไม่เขียนทับทั้งไฟล์
  /// ไฟล์เดิมเสีย/ใหญ่เกิน 4 KB = เขียนเฉพาะคีย์ที่รู้จัก (ไม่ให้ไฟล์โตเกินที่ [NslUiSettings.parse] ยอมรับ)
  @override
  Future<void> saveSettings(NslUiSettings s) async {
    final known = jsonDecode(s.toJson()) as Map<String, Object?>;
    final out = <String, Object?>{...known};
    try {
      if (await settingsFile.exists() && await settingsFile.length() <= 4096) {
        final old = jsonDecode(await settingsFile.readAsString());
        if (old is Map) {
          for (final e in old.entries) {
            if (e.key is String && !_knownSettingsKeys.contains(e.key)) out[e.key as String] = e.value;
          }
        }
      }
    } on FileSystemException {
      // อ่านของเดิมไม่ได้ = เขียนเฉพาะคีย์ที่รู้จัก
    } on FormatException {
      // ไฟล์เดิมเสีย = เขียนใหม่
    }
    var text = const JsonEncoder.withIndent('  ').convert(out);
    if (utf8.encode(text).length > 4000) text = s.toJson();
    await _atomicWrite(settingsFile, text);
  }

  /// บันทึกธีม (id ต้องใช้ได้และไม่สงวน) — เขียนแบบ atomic ให้ watcher ของแอปอื่นไม่เห็นไฟล์ครึ่งเดียว
  @override
  Future<void> saveTheme(NslThemeSpec spec) async {
    if (!isValidThemeId(spec.id) || isReservedThemeId(spec.id)) {
      throw ArgumentError.value(spec.id, 'spec.id', 'invalid or reserved theme id');
    }
    await _atomicWrite(_fileFor(spec.id), serializeNslt(spec));
  }

  @override
  Future<void> deleteTheme(String id) async {
    if (!isValidThemeId(id) || isReservedThemeId(id)) return;
    final f = _fileFor(id);
    if (await f.exists()) await f.delete();
  }

  Future<void> _atomicWrite(File target, String content) async {
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(target.path);
  }

  /// เหตุการณ์เปลี่ยนแปลงในที่เก็บ (รวมหลายเหตุการณ์ติดกันเป็นหนึ่งภายใน [debounce])
  /// ไฟล์ `.tmp` ถูกมองข้าม — เห็นเฉพาะตอน rename เสร็จ (ดูที่ปลายทางของเหตุการณ์ย้าย)
  @override
  Stream<void> watch({Duration debounce = const Duration(milliseconds: 150)}) {
    late StreamController<void> c;
    final subs = <StreamSubscription<FileSystemEvent>>[];
    Timer? timer;
    c = StreamController<void>(
      onListen: () async {
        try {
          await themesDir.create(recursive: true);
          await root.create(recursive: true);
          void onEvent(FileSystemEvent e) {
            // การเขียนแบบ atomic = สร้าง `x.tmp` แล้ว rename เป็น `x` : เหตุการณ์สุดท้ายเป็น "ย้าย" ซึ่ง `path` คือต้นทาง (.tmp)
            // จึงต้องดูปลายทางด้วย ไม่งั้นจะข้ามเหตุการณ์ที่สำคัญที่สุดไป (เดิมรอดเพราะการดูแบบ recursive ส่งเหตุการณ์ของโฟลเดอร์มาด้วย)
            final target = e is FileSystemMoveEvent ? (e.destination ?? e.path) : e.path;
            if (target.endsWith('.tmp')) return;
            timer?.cancel();
            timer = Timer(debounce, () {
              if (!c.isClosed) c.add(null);
            });
          }

          // ไฟล์ธีมอยู่ใต้ root (แบบเดิม) = ดู root ทีเดียว ; อยู่คนละที่ (Documents) = ดูทั้งสองที่ (ธีมใหม่ + ค่าตั้งจากแอปอื่น)
          final inside = themesDir.path.startsWith('${root.path}${Platform.pathSeparator}');
          if (inside) {
            subs.add(root.watch(recursive: true).listen(onEvent, onError: (_) {}));
          } else {
            subs.add(themesDir.watch().listen(onEvent, onError: (_) {}));
            subs.add(root.watch().listen(onEvent, onError: (_) {}));
          }
        } on FileSystemException {
          // ดูโฟลเดอร์ไม่ได้ = ไม่มี live reload แต่แอปยังทำงานได้
        }
      },
      onCancel: () async {
        timer?.cancel();
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return c.stream;
  }
}
