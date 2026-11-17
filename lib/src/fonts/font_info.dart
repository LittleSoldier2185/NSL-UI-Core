import 'dart:typed_data';

/// ขนาดไฟล์ฟอนต์ที่รับได้สูงสุด (ฟอนต์ละติน/ไทยทั่วไปไม่เกินสองสามเมกะไบต์ ; ฟอนต์ CJK ขนาดใหญ่ไม่ใช่เป้าหมาย)
const kMaxFontBytes = 16 * 1024 * 1024;

/// ผลตรวจไฟล์ฟอนต์ที่ผู้ใช้เลือก — **ไฟล์ถือเป็นข้อมูลไม่น่าเชื่อถือ** ฟังก์ชันตรวจไม่โยน exception และไม่อ่านเกินขอบเขตไฟล์
class NslFontInfo {
  const NslFontInfo({required this.familyName, required this.coversThai, required this.coversLatin});

  /// ชื่อ family จากตาราง `name` (null = อ่านไม่ได้ ให้ผู้ใช้ตั้งชื่อเอง)
  final String? familyName;

  /// มีอักษรไทยพอใช้งาน (พยัญชนะ สระ วรรณยุกต์ ≥ 90% ของชุดทดสอบ)
  final bool coversThai;

  /// มี A–Z a–z 0–9 ครบ (≥ 95%)
  final bool coversLatin;
}

class NslFontInspection {
  const NslFontInspection.ok(NslFontInfo this.info) : error = null;
  const NslFontInspection.failed(String this.error) : info = null;

  final NslFontInfo? info;
  final String? error;
  bool get isOk => info != null;
}

const _tagTrueType = 0x00010000;
const _tagOtto = 0x4F54544F; // 'OTTO'
const _tagTrue = 0x74727565; // 'true'
const _tagTtcf = 0x74746366; // 'ttcf'
const _tagWoff = 0x774F4646; // 'wOFF'
const _tagWoff2 = 0x774F4632; // 'wOF2'
const _maxTables = 64;
const _maxSegments = 20000;

final List<int> _thaiProbe = [
  for (var c = 0x0E01; c <= 0x0E2E; c++) c, // พยัญชนะ
  0x0E30, 0x0E31, 0x0E32, 0x0E33, 0x0E34, 0x0E35, 0x0E36, 0x0E37, 0x0E38, 0x0E39, 0x0E3A, // สระ
  for (var c = 0x0E40; c <= 0x0E4E; c++) c, // สระหน้า วรรณยุกต์ ฯลฯ
];
final List<int> _latinProbe = [
  for (var c = 0x41; c <= 0x5A; c++) c,
  for (var c = 0x61; c <= 0x7A; c++) c,
  for (var c = 0x30; c <= 0x39; c++) c,
];

/// ตรวจไฟล์ฟอนต์ TrueType/OpenType (`.ttf`/`.otf`) จาก bytes : โครงสร้างตาราง, ชื่อ family, ความครอบคลุมอักษรไทย/ละติน
///
/// ไม่รับ `.ttc` (ชุดฟอนต์), `.woff/.woff2` (Flutter โหลดไม่ได้), ไฟล์ใหญ่เกิน [kMaxFontBytes] และไฟล์ที่ตารางชี้เกินไฟล์
NslFontInspection inspectFontBytes(Uint8List bytes) {
  if (bytes.length < 12) return const NslFontInspection.failed('too small to be a font');
  if (bytes.length > kMaxFontBytes) return const NslFontInspection.failed('font file too large');
  try {
    final d = ByteData.sublistView(bytes);
    final tag = d.getUint32(0);
    if (tag == _tagTtcf) return const NslFontInspection.failed('font collections (.ttc) are not supported');
    if (tag == _tagWoff || tag == _tagWoff2) return const NslFontInspection.failed('WOFF fonts are not supported — use .ttf or .otf');
    if (tag != _tagTrueType && tag != _tagOtto && tag != _tagTrue) return const NslFontInspection.failed('not a TrueType/OpenType font');
    final numTables = d.getUint16(4);
    if (numTables == 0 || numTables > _maxTables) return const NslFontInspection.failed('invalid table count');
    if (12 + numTables * 16 > bytes.length) return const NslFontInspection.failed('table directory is cut off');

    final tables = <int, (int, int)>{}; // tag -> (offset, length)
    for (var i = 0; i < numTables; i++) {
      final r = 12 + i * 16;
      final t = d.getUint32(r), off = d.getUint32(r + 8), len = d.getUint32(r + 12);
      if (off > bytes.length || len > bytes.length - off) return const NslFontInspection.failed('a table points outside the file');
      tables[t] = (off, len);
    }
    final cmap = tables[0x636D6170]; // 'cmap'
    if (cmap == null) return const NslFontInspection.failed('no character map (cmap)');

    final covers = _cmapReader(d, cmap.$1, cmap.$2);
    if (covers == null) return const NslFontInspection.failed('unsupported or invalid character map');
    bool share(List<int> probe, double need) => probe.where(covers).length >= probe.length * need;

    final name = tables[0x6E616D65]; // 'name'
    return NslFontInspection.ok(NslFontInfo(
      familyName: name == null ? null : _familyName(d, name.$1, name.$2),
      coversThai: share(_thaiProbe, .9),
      coversLatin: share(_latinProbe, .95),
    ));
  } on RangeError {
    return const NslFontInspection.failed('font file is corrupt');
  }
}

/// ตัวเช็ก "ฟอนต์นี้มีอักษร cp ไหม" จาก subtable format 4 (BMP) หรือ 12 ที่ดีที่สุดที่พบ ; null = ไม่มี subtable ที่อ่านได้
bool Function(int)? _cmapReader(ByteData d, int base, int len) {
  if (len < 4) return null;
  final n = d.getUint16(base + 2);
  if (n == 0 || n > 64 || 4 + n * 8 > len) return null;
  int? best4, best12;
  for (var i = 0; i < n; i++) {
    final r = base + 4 + i * 8;
    final plat = d.getUint16(r), enc = d.getUint16(r + 2), off = d.getUint32(r + 4);
    if (off >= len - 2) continue;
    final fmt = d.getUint16(base + off);
    final unicode = plat == 0 || (plat == 3 && (enc == 1 || enc == 10));
    if (!unicode) continue;
    if (fmt == 12) best12 = base + off;
    if (fmt == 4) best4 = base + off;
  }
  if (best12 != null) {
    final o = best12;
    final groups = d.getUint32(o + 12);
    if (groups > _maxSegments || o + 16 + groups * 12 > base + len) return null;
    return (cp) {
      for (var g = 0; g < groups; g++) {
        final p = o + 16 + g * 12;
        if (cp >= d.getUint32(p) && cp <= d.getUint32(p + 4)) return true;
      }
      return false;
    };
  }
  if (best4 != null) {
    final o = best4;
    final segX2 = d.getUint16(o + 6);
    final seg = segX2 ~/ 2;
    if (seg == 0 || seg > _maxSegments || o + 16 + segX2 * 4 > base + len) return null;
    final endO = o + 14, startO = endO + segX2 + 2, deltaO = startO + segX2, rangeO = deltaO + segX2;
    return (cp) {
      if (cp > 0xFFFF) return false;
      for (var s = 0; s < seg; s++) {
        final end = d.getUint16(endO + s * 2);
        if (cp > end) continue;
        if (cp < d.getUint16(startO + s * 2)) return false;
        final ro = d.getUint16(rangeO + s * 2);
        if (ro == 0) return ((cp + d.getInt16(deltaO + s * 2)) & 0xFFFF) != 0;
        final gp = rangeO + s * 2 + ro + (cp - d.getUint16(startO + s * 2)) * 2;
        if (gp + 2 > base + len) return false;
        return d.getUint16(gp) != 0;
      }
      return false;
    };
  }
  return null;
}

final _nameBad = RegExp(r'[\x00-\x1f\\/:]');

/// ชื่อ family (nameID 16 ก่อน 1) ; ตัดอักขระควบคุม ยาวไม่เกิน 64 ; ไม่ผ่าน = null
String? _familyName(ByteData d, int base, int len) {
  if (len < 6) return null;
  final count = d.getUint16(base + 2), strOff = d.getUint16(base + 4);
  if (count > 2000 || 6 + count * 12 > len) return null;
  String? found;
  var foundId = 0;
  for (var i = 0; i < count; i++) {
    final r = base + 6 + i * 12;
    final plat = d.getUint16(r), id = d.getUint16(r + 6), l = d.getUint16(r + 8), o = d.getUint16(r + 10);
    if ((id != 1 && id != 16) || (found != null && id < foundId)) continue;
    final start = base + strOff + o;
    if (start + l > base + len || l == 0 || l > 256) continue;
    String? s;
    if (plat == 3 || plat == 0) {
      s = String.fromCharCodes([for (var k = 0; k + 1 < l; k += 2) d.getUint16(start + k)]);
    } else if (plat == 1) {
      s = String.fromCharCodes([for (var k = 0; k < l; k++) d.getUint8(start + k)]);
    }
    if (s == null) continue;
    s = s.replaceAll(_nameBad, '').trim();
    if (s.isEmpty || s.length > 64) continue;
    found = s;
    foundId = id;
  }
  return found;
}

/// ปัญหาที่พบเมื่อดูฟอนต์ละติน + ฟอนต์ไทยพร้อมกัน
enum NslFontIssue {
  /// ฟอนต์ที่เลือกให้อักษรไทยไม่มีอักษรไทย → ช่องไทยไม่มีผล
  thaiFontLacksThai,

  /// ฟอนต์ที่เลือกให้ละตินไม่มีอักษรละตินครบ → อักษรละตินที่ขาดจะตกไปฟอนต์ถัดไป
  latinFontLacksLatin,

  /// ทั้งสองฟอนต์มีทั้งไทยและละติน → บังคับให้ไทย/ละตินใช้คนละฟอนต์ไม่ได้ (Flutter เลือกฟอนต์ตามลำดับต่อตัวอักษร) อักษรไทยจะใช้ฟอนต์ละติน
  bothCoverBoth,
}

class NslFontPlan {
  const NslFontPlan({this.thaiFirst = false, this.issues = const []});

  /// ต้องวางฟอนต์ไทยไว้ก่อนฟอนต์ละติน (ดู `NslType.thaiFirst`)
  final bool thaiFirst;
  final List<NslFontIssue> issues;
}

/// จัดลำดับฟอนต์ละติน [latin] และฟอนต์ไทย [thai] ให้ตัวอักษรแต่ละสคริปต์ได้ฟอนต์ที่ผู้ใช้เลือกมากที่สุดเท่าที่ทำได้
/// (null = ฟอนต์นั้นไม่ใช่ไฟล์ของผู้ใช้/ยังไม่รู้ ไม่เอามาตัดสิน)
NslFontPlan planFontOrder({NslFontInfo? latin, NslFontInfo? thai}) {
  final issues = <NslFontIssue>[];
  if (thai != null && !thai.coversThai) issues.add(NslFontIssue.thaiFontLacksThai);
  if (latin != null && !latin.coversLatin) issues.add(NslFontIssue.latinFontLacksLatin);
  if (latin == null || thai == null || !thai.coversThai) return NslFontPlan(issues: issues);
  if (!latin.coversThai) return NslFontPlan(issues: issues); // ละติน→ไทย ได้ตามที่เลือก
  if (!thai.coversLatin) return NslFontPlan(thaiFirst: true, issues: issues); // ไทยก่อน ละตินตกมาที่ฟอนต์ละติน
  return NslFontPlan(issues: [...issues, NslFontIssue.bothCoverBoth]);
}
