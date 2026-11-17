import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

Future<void> _pump(WidgetTester tester, Widget w, {double width = 360}) async {
  final t = resolveTokens(kBuiltinDefault, Brightness.light);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(platform: TargetPlatform.windows, extensions: [NslTheme(t)]),
    home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: w))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ปุ่มใน trailing : กดแล้วไม่เรียก onTap ของแถว และกดแถวไม่เรียกปุ่ม', (tester) async {
    var row = 0, menu = 0;
    await _pump(
      tester,
      NslListRow(
        title: 'เพลง A',
        subtitle: 'ศิลปิน',
        onTap: () => row++,
        trailing: NslIconButton(icon: Icons.more_vert, tooltip: 'เมนูเพลง', onPressed: () => menu++),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    expect((row, menu), (0, 1));
    await tester.tap(find.text('เพลง A'));
    expect((row, menu), (1, 1));
  });

  testWidgets('ปุ่มใน trailing ยังอยู่ใน semantics (แถวไม่กลืน)', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      NslListRow(
        title: 'เพลง A',
        onTap: () {},
        trailing: NslIconButton(icon: Icons.more_vert, tooltip: 'เมนูเพลง', onPressed: () {}),
      ),
    );
    expect(find.bySemanticsLabel('เมนูเพลง'), findsOneWidget);
    expect(find.bySemanticsLabel('เพลง A'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('onLongPress ทำงาน และมี action longPress ใน semantics', (tester) async {
    final handle = tester.ensureSemantics();
    var long = 0;
    await _pump(tester, NslListRow(title: 'เพลง A', onTap: () {}, onLongPress: () => long++));
    await tester.longPress(find.text('เพลง A'));
    expect(long, 1);
    expect(tester.getSemantics(find.bySemanticsLabel('เพลง A')).getSemanticsData().hasAction(SemanticsAction.longPress), isTrue);
    handle.dispose();
  });

  testWidgets('selected + trailing : พื้นคลุมทั้งแถวรวม trailing', (tester) async {
    await _pump(tester, NslListRow(title: 'A', selected: true, onTap: () {}, trailing: const Icon(Icons.chevron_right)));
    final t = resolveTokens(kBuiltinDefault, Brightness.light);
    final box = tester.widget<DecoratedBox>(find.ancestor(of: find.byIcon(Icons.chevron_right), matching: find.byType(DecoratedBox)).first);
    expect((box.decoration as BoxDecoration).color, t.colors.selected);
  });

  testWidgets('trailing + ข้อความยาวในพื้นที่แคบ ไม่ overflow', (tester) async {
    await _pump(
      tester,
      NslListRow(title: 'ชื่อเพลงที่ยาวมากมากมากมากมากมากมาก' * 2, subtitle: 'ศิลปินที่ยาวมากมากมาก' * 2, leading: const Icon(Icons.music_note), onTap: () {}, trailing: const Icon(Icons.more_vert)),
      width: 200,
    );
    expect(tester.takeException(), isNull);
  });
}
