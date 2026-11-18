// เรนเดอร์จริง (เอนจิน Flutter + ฟอนต์จริง) ว่าข้อความไทยที่มีสระ/วรรณยุกต์ซ้อน ได้ฟอนต์ไทยที่ผู้ใช้เลือก
// ไม่ถูกฟอนต์ละตินแย่งไป และไม่ตกเป็นสี่เหลี่ยม — เทียบพิกเซลกับการเรนเดอร์ด้วยฟอนต์ไทยล้วน
// ฟอนต์ใน C:\Windows\Fonts ที่ไม่มีบนเครื่องนี้ → เคสนั้นถูกข้าม (Noto ของ nsl_ui มีเสมอ)
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

// ไม่ใส่ช่องว่าง: ช่องว่างเป็นอักขระละติน ฟอนต์ละตินจึงวาดต่างจาก Noto ได้ตามปกติ
const _thaiText = 'ที่นั่งกิ่งก้านปู่ผู้ใหญ่น้ำเต้าหู้ก็ได้เกี๋ยว';

Future<void> _load(String family, Uint8List bytes) async {
  final l = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length)));
  await l.load();
}

Uint8List? _file(String path) {
  final f = File(path);
  return f.existsSync() ? f.readAsBytesSync() : null;
}

class _Ink {
  _Ink(this.hash, this.w, this.h, this.box, this.inked);
  final int hash;
  final int w, h;
  final ui.Rect box; // กรอบพิกเซลที่มีหมึก
  final int inked;
}

Future<_Ink> _paint(String family, List<String> fallback, {String text = _thaiText, double size = 40}) async {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontFamily: family, fontFamilyFallback: fallback, fontSize: size, color: const ui.Color(0xFF000000))),
    textDirection: TextDirection.ltr,
  )..layout();
  const pad = 20.0;
  final w = (tp.width + pad * 2).ceil(), h = (tp.height + pad * 2).ceil();
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  tp.paint(c, const ui.Offset(pad, pad));
  final img = await rec.endRecording().toImage(w, h);
  final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  var minX = w, minY = h, maxX = -1, maxY = -1, inked = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      if (data[i] < 200) {
        inked++;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  var hash = 17;
  for (final b in data) {
    hash = (hash * 31 + b) & 0x3fffffff;
  }
  return _Ink(hash, w, h, inked == 0 ? ui.Rect.zero : ui.Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX + 1.0, maxY + 1.0), inked);
}

void main() {
  final noto = File('assets/fonts/NotoSansThai-Regular.ttf').readAsBytesSync();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _load('RNoto', noto);
    for (final (fam, path) in [
      ('RArial', 'C:/Windows/Fonts/arial.ttf'),
      ('RConsolas', 'C:/Windows/Fonts/consola.ttf'),
      ('RCambria', 'C:/Windows/Fonts/cambriab.ttf'),
      ('RLeelawadee', 'C:/Windows/Fonts/LeelawUI.ttf'),
    ]) {
      final b = _file(path);
      if (b != null) await _load(fam, b);
    }
  });

  bool has(String path) => File(path).existsSync();

  testWidgets('ฐาน: Noto ล้วนวาดข้อความไทยสระซ้อนได้จริง (มีหมึก ไม่ว่าง)', (t) async {
    await t.runAsync(() async {
      final base = await _paint('RNoto', const []);
      expect(base.inked, greaterThan(500));
      // สระบน+วรรณยุกต์ต้องยกสูงกว่าตัวอักษรฐาน — กรอบหมึกสูงกว่าข้อความที่ไม่มีเครื่องหมาย
      final plain = await _paint('RNoto', const [], text: 'กนงมาว');
      expect(base.box.height, greaterThan(plain.box.height));
    });
  });

  for (final (latinFam, path) in [
    ('RArial', 'C:/Windows/Fonts/arial.ttf'),
    ('RConsolas', 'C:/Windows/Fonts/consola.ttf'),
    ('RCambria', 'C:/Windows/Fonts/cambriab.ttf'),
  ]) {
    testWidgets('ละติน=$latinFam (ไม่มีไทย) + ไทย=Noto : ข้อความไทยเหมือน Noto ล้วนทุกพิกเซล', (t) async {
      if (!has(path)) return;
      await t.runAsync(() async {
        final base = await _paint('RNoto', const []);
        final type = const NslType(family: 'RArial', familyThai: 'RNoto'); // รูปแบบเดียวกับที่แอปส่งให้ธีม
        final tt = NslType(family: latinFam, familyThai: 'RNoto');
        expect(type.effectiveFamily, 'RArial');
        final got = await _paint(tt.effectiveFamily, tt.fallback);
        expect(got.hash, base.hash, reason: 'อักษรไทยต้องมาจากฟอนต์ไทย ไม่ใช่ถูกบัง/ตกเป็น tofu');
        expect(got.box, base.box);
      });
    });
  }

  testWidgets('ละตินมีไทยด้วย (Leelawadee) + ไทย=Noto ที่ไม่มีละติน : plan → thaiFirst แล้วไทยได้ Noto', (t) async {
    if (!has('C:/Windows/Fonts/LeelawUI.ttf')) return;
    await t.runAsync(() async {
      final leela = inspectFontBytes(_file('C:/Windows/Fonts/LeelawUI.ttf')!).info!;
      final notoInfo = inspectFontBytes(noto).info!;
      // Noto Sans Thai ของ nsl_ui มีละตินด้วย จึงต้องสร้างฟอนต์ไทยล้วนจำลองไม่ได้ — ใช้ผลตรวจจริง ถ้าเป็น bothCoverBoth ให้ยืนยันคำเตือนแทน
      final plan = planFontOrder(latin: leela, thai: notoInfo);
      if (notoInfo.coversLatin) {
        expect(plan.issues, contains(NslFontIssue.bothCoverBoth));
        expect(plan.thaiFirst, isFalse);
        return;
      }
      final base = await _paint('RNoto', const []);
      final first = NslType(family: 'RLeelawadee', familyThai: 'RNoto', thaiFirst: const {'family'});
      final got = await _paint(first.effectiveFamily, first.fallback);
      expect(got.hash, base.hash);
    });
  });

  testWidgets('ไทย=Noto เท่านั้น (ช่องละตินว่าง) : ไทยได้ Noto ไม่ถูกบัง', (t) async {
    await t.runAsync(() async {
      final base = await _paint('RNoto', const []);
      const ty = NslType(familyThai: 'RNoto');
      final got = await _paint(ty.effectiveFamily, ty.fallback);
      expect(got.hash, base.hash);
    });
  });

  testWidgets('ข้อจำกัดที่ทราบ: ละตินมีไทยด้วย + ไทยมีละตินด้วย → ไทยถูกวาดด้วยฟอนต์ละติน (ไม่ใช่ Noto) ตรงกับคำเตือน bothCoverBoth', (t) async {
    if (!has('C:/Windows/Fonts/LeelawUI.ttf')) return;
    await t.runAsync(() async {
      final base = await _paint('RNoto', const []);
      const ty = NslType(family: 'RLeelawadee', familyThai: 'RNoto');
      final got = await _paint(ty.effectiveFamily, ty.fallback);
      expect(got.inked, greaterThan(500)); // ยังแสดงไทยครบ ไม่ tofu
      expect(got.hash, isNot(base.hash), reason: 'ถ้าเท่ากัน คำเตือน bothCoverBoth จะไม่จริงอีกต่อไป');
    });
  });

  testWidgets('ข้อความผสมไทย+ละติน : ละตินใช้ฟอนต์ละติน ไทยใช้ฟอนต์ไทย (ไม่เหมือน Noto ล้วน แต่กรอบหมึกไทยไม่ล้ม)', (t) async {
    if (!has('C:/Windows/Fonts/arial.ttf')) return;
    await t.runAsync(() async {
      const mixed = 'Report ที่นั่ง 123 กิ่ง';
      final ty = const NslType(family: 'RArial', familyThai: 'RNoto');
      final got = await _paint(ty.effectiveFamily, ty.fallback, text: mixed);
      final notoOnly = await _paint('RNoto', const [], text: mixed);
      expect(got.inked, greaterThan(300));
      expect(got.hash, isNot(notoOnly.hash), reason: 'ส่วนละตินต้องเป็น Arial จริง');
      // ส่วนไทยล้วนในข้อความเดียวกันเหมือน Noto ล้วน
      final thaiPart = await _paint(ty.effectiveFamily, ty.fallback, text: 'ที่นั่งกิ่ง');
      final thaiNoto = await _paint('RNoto', const [], text: 'ที่นั่งกิ่ง');
      expect(thaiPart.hash, thaiNoto.hash);
    });
  });

  testWidgets('ฟอนต์ที่ผู้ใช้เลือกหาย/ยังไม่ลงทะเบียน : ข้อความไทยยังแสดง (ถอยไป Noto ท้ายลำดับ) ไม่ว่าง', (t) async {
    await t.runAsync(() async {
      // 'RNoto' ลงทะเบียนแทน Noto ของ nsl_ui ในเทสต์นี้ ; ชื่อ family ของ nsl_ui ที่ยังไม่ได้โหลดในเทสต์จะถอยเป็นฟอนต์ระบบ — ตรวจแค่ว่าไม่โยนและมีหมึก
      const ty = NslType(family: 'GhostLatin', familyThai: 'GhostThai');
      final got = await _paint(ty.effectiveFamily, [...ty.fallback, 'RNoto']);
      final base = await _paint('RNoto', const []);
      expect(got.hash, base.hash);
    });
  });
}
