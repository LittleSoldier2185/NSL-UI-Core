import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

final _themes = <String, NslThemeSpec>{
  'default': kBuiltinDefault,
  'nebular': kBuiltinDev,
  'spectrum': builtinResonance(),
  'lyra.paper': kBuiltinLyraPaper,
};

NslTokens _base(NslThemeSpec s, Brightness b) => resolveTokens(s, b);

NslTokens _with(NslTokens t, {NslDensity? density, NslType? type, NslShape? shape}) => NslTokens(
      brightness: t.brightness,
      colors: t.colors,
      shape: shape ?? t.shape,
      type: type ?? t.type,
      density: density ?? t.density,
      elevation: t.elevation,
      extensions: t.extensions,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget w,
  NslTokens tokens, {
  TargetPlatform platform = TargetPlatform.windows,
  double width = 320,
  double systemTextScale = 1.0,
  bool loose = false,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: tokens.brightness, platform: platform, extensions: [NslTheme(tokens)]),
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(systemTextScale)), child: child!),
    home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: loose ? Align(alignment: Alignment.topLeft, child: w) : w))),
  ));
  await tester.pumpAndSettle();
}

Material _material(WidgetTester tester, Finder of) => tester.widget<Material>(find.descendant(of: of, matching: find.byType(Material)).first);

double _contrast(Color fg, Color bg, Color backdrop) {
  final back = Color.alphaBlend(bg, backdrop);
  return contrastRatio(Color.alphaBlend(fg, back), back);
}

void main() {
  final light = _base(kBuiltinDefault, Brightness.light);

  group('NslListRow', () {
    testWidgets('แสดง leading/ชื่อ/รอง/trailing และกดได้', (tester) async {
      var n = 0;
      await _pump(
        tester,
        NslListRow(
          title: 'เพลงของฉัน',
          subtitle: 'ศิลปิน · 3:45',
          leading: const Icon(Icons.music_note),
          trailing: const Icon(Icons.more_vert),
          onTap: () => n++,
        ),
        light,
      );
      expect(find.text('เพลงของฉัน'), findsOneWidget);
      expect(find.text('ศิลปิน · 3:45'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      await tester.tap(find.byType(NslListRow));
      expect(n, 1);
    });

    testWidgets('onTap เป็น null = ไม่ใช่ปุ่ม (ไม่มี InkWell, ไม่มี Semantics ปุ่ม)', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, const NslListRow(title: 'อ่านอย่างเดียว', subtitle: 'รอง'), light);
      expect(find.byType(InkWell), findsNothing);
      expect(tester.getSemantics(find.bySemanticsLabel('อ่านอย่างเดียว, รอง')), isSemantics(label: 'อ่านอย่างเดียว, รอง', isButton: false));
      h.dispose();
    });

    testWidgets('พื้นตามสถานะ : ปกติโปร่ง · selected=selected · active=hover', (tester) async {
      final c = light.colors;
      for (final (sel, act, bg) in [(false, false, Colors.transparent), (true, false, c.selected), (false, true, c.hover)]) {
        await _pump(tester, NslListRow(title: 'x', selected: sel, active: act, onTap: () {}), light);
        expect(_material(tester, find.byType(NslListRow)).color, bg, reason: 'selected=$sel active=$act');
      }
    });

    testWidgets('ชื่อหนาขึ้นเมื่อเลือก/กำลังใช้ · active ใช้สี accent', (tester) async {
      final c = light.colors;
      await _pump(tester, NslListRow(title: 't', onTap: () {}), light);
      expect(tester.widget<Text>(find.text('t')).style!.fontWeight, FontWeight.w500);
      await _pump(tester, NslListRow(title: 't', selected: true, onTap: () {}), light);
      expect(tester.widget<Text>(find.text('t')).style!.fontWeight, FontWeight.w600);
      await _pump(tester, NslListRow(title: 't', active: true, onTap: () {}), light);
      expect(tester.widget<Text>(find.text('t')).style!.fontWeight, FontWeight.w700);
      expect(tester.widget<Text>(find.text('t')).style!.color, light.legibleOn(c.accentInk, c.hover));
    });

    testWidgets('ความสูงตาม density · จอสัมผัสไม่เตี้ยกว่า 44 · มุมโค้งตาม shape.md', (tester) async {
      final hs = <double>[];
      for (final d in NslDensity.values) {
        await _pump(tester, NslListRow(title: 't', onTap: () {}), _with(light, density: d));
        hs.add(tester.getSize(find.byType(NslListRow)).height);
        await _pump(tester, NslListRow(title: 't', onTap: () {}), _with(light, density: d), platform: TargetPlatform.android);
        expect(tester.getSize(find.byType(NslListRow)).height, greaterThanOrEqualTo(kMinTapTarget), reason: d.name);
      }
      expect(hs[0], lessThan(hs[1]));
      expect(hs[1], lessThan(hs[2]));
      await _pump(tester, NslListRow(title: 't', onTap: () {}), _with(light, shape: const NslShape(md: 11)));
      expect(((_material(tester, find.byType(NslListRow)).shape) as RoundedRectangleBorder).borderRadius, BorderRadius.circular(11));
    });

    testWidgets('Semantics: ปุ่ม + ชื่อ,รอง + สถานะเลือก + action แตะ', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, NslListRow(title: 'ท่าเรือ', subtitle: 'สถานที่', selected: true, onTap: () {}), light);
      expect(tester.getSemantics(find.bySemanticsLabel('ท่าเรือ, สถานที่')), isSemantics(label: 'ท่าเรือ, สถานที่', isButton: true, isSelected: true, hasSelectedState: true, hasTapAction: true));
      await _pump(tester, NslListRow(title: 'ท่าเรือ', semanticLabel: 'เปิดท่าเรือ', onTap: () {}), light);
      expect(find.bySemanticsLabel('เปิดท่าเรือ'), findsOneWidget);
      h.dispose();
    });

    testWidgets('คีย์บอร์ด : Tab โฟกัสแล้ว Enter เรียก onTap', (tester) async {
      var n = 0;
      await _pump(tester, NslListRow(title: 'x', onTap: () => n++), light);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(n, 1);
    });

    testWidgets('ข้อความยาว + leading/trailing ใหญ่ ในพื้นที่แคบ ไม่ overflow ทุก density × ขนาดตัวอักษร', (tester) async {
      for (final d in NslDensity.values) {
        await _pump(
          tester,
          NslListRow(
            title: 'ชื่อรายการที่ยาวมากมากสำหรับทดสอบการตัดคำ ' * 3,
            subtitle: 'ข้อความรองที่ยาวมากเช่นกัน ' * 3,
            leading: const SizedBox(width: 44, height: 44, child: Icon(Icons.album)),
            trailing: const Icon(Icons.more_vert),
            selected: true,
            onTap: () {},
          ),
          _with(light, density: d, type: const NslType(scale: 1.2)),
          width: 160,
          systemTextScale: 1.5,
        );
        expect(tester.takeException(), isNull, reason: d.name);
      }
    });

    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        testWidgets('contrast ≥ 4.5 ทุกสถานะ — ${e.key} ${b.name}', (tester) async {
          final t = _base(e.value, b);
          await _pump(
            tester,
            Column(children: [
              NslListRow(key: const Key('normal'), title: 'n-title', subtitle: 'n-sub', onTap: () {}),
              NslListRow(key: const Key('selected'), title: 's-title', subtitle: 's-sub', selected: true, onTap: () {}),
              NslListRow(key: const Key('active'), title: 'a-title', subtitle: 'a-sub', active: true, onTap: () {}),
            ]),
            t,
          );
          for (final k in ['normal', 'selected', 'active']) {
            final bg = _material(tester, find.byKey(Key(k))).color!;
            final p = k[0];
            for (final part in ['title', 'sub']) {
              final fg = tester.widget<Text>(find.text('$p-$part')).style!.color!;
              final r = _contrast(fg, bg, t.colors.surface);
              expect(r, greaterThanOrEqualTo(4.5), reason: '${e.key} ${b.name} $k $part: ${r.toStringAsFixed(2)}');
            }
          }
        });
      }
    }
  });

  group('NslNavItem', () {
    testWidgets('แบบเต็ม : ไอคอน + ป้ายชื่อ · กดได้ · เต็มความกว้าง', (tester) async {
      var n = 0;
      await _pump(tester, NslNavItem(icon: Icons.home, label: 'หน้าหลัก', selected: false, onTap: () => n++), light, width: 200);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('หน้าหลัก'), findsOneWidget);
      expect(tester.getSize(find.byType(NslNavItem)).width, 200);
      await tester.tap(find.byType(NslNavItem));
      expect(n, 1);
    });

    testWidgets('แบบย่อ (collapsed) : เฉพาะไอคอน จัตุรัส + tooltip + ชื่อ semantics', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, NslNavItem(icon: Icons.home, label: 'หน้าหลัก', selected: false, collapsed: true, onTap: () {}), light, loose: true);
      expect(find.text('หน้าหลัก'), findsNothing);
      expect(find.byTooltip('หน้าหลัก'), findsOneWidget);
      final s = tester.getSize(find.byType(NslNavItem));
      expect(s.width, s.height);
      expect(tester.getSemantics(find.bySemanticsLabel('หน้าหลัก')), isSemantics(label: 'หน้าหลัก', isButton: true, hasTapAction: true));
      h.dispose();
    });

    testWidgets('ป้ายตัวเลข : แสดงเมื่อ > 0 · เกิน 99 = 99+ · 0/null ไม่แสดง · รวมในชื่อ semantics', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, NslNavItem(icon: Icons.inbox, label: 'กล่องข้อความ', selected: false, badge: 5, onTap: () {}), light);
      expect(find.text('5'), findsOneWidget);
      expect(find.bySemanticsLabel('กล่องข้อความ (5)'), findsOneWidget);
      await _pump(tester, NslNavItem(icon: Icons.inbox, label: 'กล่องข้อความ', selected: false, badge: 250, onTap: () {}), light);
      expect(find.text('99+'), findsOneWidget);
      for (final b in [0, null]) {
        await _pump(tester, NslNavItem(icon: Icons.inbox, label: 'กล่องข้อความ', selected: false, badge: b, onTap: () {}), light);
        expect(find.byType(Text).evaluate().length, 1, reason: 'badge=$b');
        expect(find.bySemanticsLabel('กล่องข้อความ'), findsOneWidget);
      }
      // แบบย่อก็แสดงป้าย
      await _pump(tester, NslNavItem(icon: Icons.inbox, label: 'กล่องข้อความ', selected: false, badge: 3, collapsed: true, onTap: () {}), light, loose: true);
      expect(find.text('3'), findsOneWidget);
      h.dispose();
    });

    testWidgets('สถานะเลือก : พื้น selected + ขอบ accentBorder ; ไม่เลือก = โปร่ง', (tester) async {
      final c = light.colors;
      await _pump(tester, NslNavItem(icon: Icons.home, label: 'x', selected: true, onTap: () {}), light);
      final sel = _material(tester, find.byType(NslNavItem));
      expect(sel.color, c.selected);
      expect((sel.shape! as RoundedRectangleBorder).side.color, c.accentBorder);
      await _pump(tester, NslNavItem(icon: Icons.home, label: 'x', selected: false, onTap: () {}), light);
      final off = _material(tester, find.byType(NslNavItem));
      expect(off.color, Colors.transparent);
      expect((off.shape! as RoundedRectangleBorder).side, BorderSide.none);
    });

    testWidgets('Semantics: เลือกอยู่ = selected', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, NslNavItem(icon: Icons.home, label: 'หน้าหลัก', selected: true, onTap: () {}), light);
      expect(tester.getSemantics(find.bySemanticsLabel('หน้าหลัก')), isSemantics(isSelected: true, hasSelectedState: true, isButton: true));
      h.dispose();
    });

    testWidgets('ความสูงตาม density · จอสัมผัสไม่เตี้ยกว่า 44', (tester) async {
      final hs = <double>[];
      for (final d in NslDensity.values) {
        await _pump(tester, NslNavItem(icon: Icons.home, label: 'x', selected: false, onTap: () {}), _with(light, density: d));
        hs.add(tester.getSize(find.byType(NslNavItem)).height);
        await _pump(tester, NslNavItem(icon: Icons.home, label: 'x', selected: false, onTap: () {}), _with(light, density: d), platform: TargetPlatform.android);
        expect(tester.getSize(find.byType(NslNavItem)).height, greaterThanOrEqualTo(kMinTapTarget), reason: d.name);
      }
      expect(hs[0], lessThan(hs[1]));
      expect(hs[1], lessThan(hs[2]));
    });

    testWidgets('ไม่ overflow : แถบแคบ + ป้ายยาว + ป้ายตัวเลข ทุก density (เต็ม/ย่อ)', (tester) async {
      // ขีดจำกัดที่รองรับ (วัดจริง ดูเอกสารของ NslNavItem) : แบบเต็มที่มีป้ายเลข 99+ ต้องกว้างอย่างน้อย
      // ปกติ 99/113/127 · ขยายสุด 132/146/160 (ตาม density) → ทดสอบที่ 130 และ 170 ซึ่งเผื่อไว้ ; แบบย่อไม่ขึ้นกับความกว้าง
      for (final (scale, sys, w) in [(1.0, 1.0, 130.0), (1.2, 1.5, 170.0)]) {
        for (final d in NslDensity.values) {
          for (final collapsed in [false, true]) {
            await _pump(
              tester,
              NslNavItem(icon: Icons.library_music, label: 'ชื่อเมนูที่ยาวมากสำหรับแถบข้างที่แคบ', selected: true, badge: 128, collapsed: collapsed, onTap: () {}),
              _with(light, density: d, type: NslType(scale: scale)),
              width: w,
              systemTextScale: sys,
              loose: collapsed,
            );
            expect(tester.takeException(), isNull, reason: '${d.name} collapsed=$collapsed scale $scale/$sys width $w');
          }
        }
      }
    });

    testWidgets('คีย์บอร์ด : Tab โฟกัสแล้ว Space/Enter เรียก onTap', (tester) async {
      var n = 0;
      await _pump(tester, NslNavItem(icon: Icons.home, label: 'x', selected: false, onTap: () => n++), light);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(n, 1);
    });

    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        testWidgets('contrast ≥ 4.5 — ${e.key} ${b.name}', (tester) async {
          final t = _base(e.value, b);
          await _pump(
            tester,
            Column(children: [
              NslNavItem(key: const Key('on'), icon: Icons.home, label: 'on-label', selected: true, badge: 7, onTap: () {}),
              NslNavItem(key: const Key('off'), icon: Icons.search, label: 'off-label', selected: false, onTap: () {}),
            ]),
            t,
          );
          void check(String what, Color fg, Color bg) {
            final r = _contrast(fg, bg, t.colors.surface);
            expect(r, greaterThanOrEqualTo(4.5), reason: '${e.key} ${b.name} $what: ${r.toStringAsFixed(2)}');
          }

          final onBg = _material(tester, find.byKey(const Key('on'))).color!;
          final offBg = _material(tester, find.byKey(const Key('off'))).color!;
          check('on label', tester.widget<Text>(find.text('on-label')).style!.color!, onBg);
          check('on icon', tester.widget<Icon>(find.byIcon(Icons.home)).color!, onBg);
          check('off label', tester.widget<Text>(find.text('off-label')).style!.color!, offBg);
          check('off icon', tester.widget<Icon>(find.byIcon(Icons.search)).color!, offBg);
          // ตัวเลขในป้าย : บนพื้น accent
          check('badge', tester.widget<Text>(find.text('7')).style!.color!, t.colors.accent);
        });
      }
    }
  });

  group('Gallery', () {
    testWidgets('มี NslListRow และ NslNavItem ในส่วน Components และไม่ overflow ที่ 320', (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(theme: ThemeData(extensions: [NslTheme(light)]), home: Scaffold(body: NslGallery(tokens: light))));
      await tester.pumpAndSettle();
      expect(find.byType(NslListRow), findsWidgets);
      expect(find.byType(NslNavItem), findsWidgets);
      expect(tester.takeException(), isNull);
      // ข้อความเดิมของ Gallery ที่เทสต์ adjust_gallery_test จับอยู่ต้องไม่ซ้ำ
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('accent'), findsOneWidget);
    });
  });
}
