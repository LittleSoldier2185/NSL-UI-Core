// ตัวตรวจฟอนต์กับไฟล์ฟอนต์จริง (ฟอนต์จำลองในเทสต์อื่นสร้างเองจึงไม่พิสูจน์ว่าอ่าน cmap ของจริงได้)
// ไฟล์ที่ไม่มีบนเครื่องนี้ถูกข้าม — nsl_ui แพ็ก Noto Sans Thai มาเอง จึงมีอย่างน้อยหนึ่งไฟล์เสมอ
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

void main() {
  final cases = <(String, bool, bool)>[
    ('assets/fonts/NotoSansThai-Regular.ttf', true, true), // ไทย + ละติน
    ('assets/fonts/NotoSansThai-Bold.ttf', true, true),
    ('C:/Windows/Fonts/LeelawUI.ttf', true, true),
    ('C:/Windows/Fonts/arial.ttf', false, true), // ละตินอย่างเดียว
    ('C:/Windows/Fonts/consola.ttf', false, true),
    ('C:/Windows/Fonts/cambriab.ttf', false, true),
  ];
  for (final (path, thai, latin) in cases) {
    test('real font: $path', () {
      final f = File(path);
      if (!f.existsSync()) {
        markTestSkipped('not on this machine');
        return;
      }
      final r = inspectFontBytes(f.readAsBytesSync());
      expect(r.isOk, isTrue, reason: r.error);
      expect(r.info!.coversThai, thai, reason: 'Thai');
      expect(r.info!.coversLatin, latin, reason: 'Latin');
      expect(r.info!.familyName, isNotNull);
      // ignore: avoid_print
      print('  ${f.uri.pathSegments.last}: ${r.info!.familyName} thai=${r.info!.coversThai} latin=${r.info!.coversLatin}');
    });
  }

  test('collections (.ttc) are refused, not misread', () {
    final f = File('C:/Windows/Fonts/angsana.ttc');
    if (!f.existsSync()) {
      markTestSkipped('not on this machine');
      return;
    }
    expect(inspectFontBytes(f.readAsBytesSync()).error, contains('.ttc'));
  });

  test('the real engine accepts a real font through the default registrar', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final f = File('C:/Windows/Fonts/consola.ttf');
    if (!f.existsSync()) {
      markTestSkipped('not on this machine');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('nsl_real_font_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final s = NslFontStore(Directory('${dir.path}/Fonts'));
    final r = await s.importFont(f.readAsBytesSync());
    expect(r.isOk, isTrue, reason: r.error);
    expect(s.infos.keys, [r.font!.family]); // registered with the real FontLoader
  });
}
