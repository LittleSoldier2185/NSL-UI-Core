import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

NslTokens _tok(String extra) => resolveTokens(
    parseNslt('{"schema":1,"id":"t","name":"t","extends":"nsl.nebular"$extra}').spec!, Brightness.light, lookup: builtinThemeById);

void main() {
  test('ค่าเริ่มต้น = ตัวคูณ 1 ทุกตัว (parity)', () {
    final t = _tok('');
    expect(t.radiusFactor, 1.0);
    expect(t.radius(14), 14);
    expect(t.fontSizeFactor, 1.0);
    expect(t.visualDensity, VisualDensity.standard);
  });

  test('shape/type/density จากไฟล์ → ตัวคูณ', () {
    final t = _tok(',"shape":{"radius":{"md":16}},"type":{"scale":1.1},"density":"compact"');
    expect(t.radiusFactor, 2.0);
    expect(t.radius(14), 28);
    expect(t.fontSizeFactor, 1.1);
    expect(t.visualDensity.horizontal, -2);
    expect(_tok(',"density":"comfortable"').visualDensity.vertical, 1);
  });

  test('ค่านอกช่วงถูก clamp โดย parser แล้ว radius ไม่ติดลบ/ไม่เกิน pill', () {
    final t = _tok(',"shape":{"radius":{"md":99999}},"type":{"scale":50}');
    expect(t.fontSizeFactor, lessThanOrEqualTo(NslType.maxScale));
    expect(t.radius(14), lessThanOrEqualTo(NslShape.maxRadius));
    expect(t.radius(0), 0);
  });

  testWidgets('NslGallery แสดง widget มาตรฐานและตารางสี โดยไม่ error', (tester) async {
    final t = _tok('');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, visualDensity: t.visualDensity),
      home: Scaffold(body: NslGallery(tokens: t)),
    ));
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('accent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
