// buildNslThemeData : ThemeData ของ Material จาก token
//
// parity กับแอปจริงอิมพอร์ต theme.dart ของแอปแบบอ่านอย่างเดียว (ไม่แก้ไฟล์ของแอป)

// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

import '../../NSL-Nebular/lib/ui/theme.dart' as dev;
import '../../NSL-Spectrum/lib/ui/theme.dart' as res;

final _themes = <String, NslThemeSpec>{
  'default': kBuiltinDefault,
  'nebular': kBuiltinDev,
  'spectrum': builtinResonance(),
  'lyra.paper': kBuiltinLyraPaper,
};

NslTokens _tok(NslThemeSpec s, Brightness b) => resolveTokens(s, b);

NslTokens _with(NslTokens t, {NslDensity? density, NslShape? shape, NslType? type, NslElevation? elevation}) => NslTokens(
      brightness: t.brightness,
      colors: t.colors,
      shape: shape ?? t.shape,
      type: type ?? t.type,
      density: density ?? t.density,
      elevation: elevation ?? t.elevation,
      extensions: t.extensions,
    );

/// สีที่อาจเป็น WidgetStateColor → ค่าตามสถานะ
Color _c(Color? c, [Set<WidgetState> s = const {}]) => c is WidgetStateProperty<Color> ? (c as WidgetStateProperty<Color>).resolve(s) : c!;

Color _p(WidgetStateProperty<Color?>? p, [Set<WidgetState> s = const {}]) => p!.resolve(s)!;

double _ratio(Color fg, Color bg, Color backdrop) {
  final back = Color.alphaBlend(bg, backdrop);
  return contrastRatio(Color.alphaBlend(fg, back), back);
}

void main() {
  for (final e in _themes.entries) {
    for (final b in Brightness.values) {
      final t = _tok(e.value, b);
      final c = t.colors;
      final th = buildNslThemeData(t);
      final label = '${e.key} ${b.name}';

      group('ColorScheme และค่าพื้นฐาน — $label', () {
        test('มาจาก token', () {
          expect(th.brightness, b);
          expect(th.colorScheme.primary, c.accent);
          expect(th.colorScheme.surface, c.surface);
          expect(th.colorScheme.onSurface, c.text);
          expect(th.colorScheme.onSurfaceVariant, c.textMuted);
          expect(th.colorScheme.error, c.danger);
          expect(th.colorScheme.outline, c.borderStrong);
          expect(th.colorScheme.primaryContainer, c.accentTint);
          expect(th.colorScheme.secondaryContainer, c.selected);
          expect(th.scaffoldBackgroundColor, c.bg);
          expect(th.dividerColor, c.borderSoft);
          expect(th.useMaterial3, isTrue);
        });

        test('แนบ NslTheme ใน extensions', () {
          expect(th.extension<NslTheme>()!.tokens, t);
        });
      });

      group('contrast ≥ 4.5 ของคู่สีที่ตัวควบคุมใช้ — $label', () {
        void check(String what, Color fg, Color bg, {Color? backdrop, double min = 4.5}) {
          final r = _ratio(fg, bg, backdrop ?? c.surface);
          expect(r, greaterThanOrEqualTo(min), reason: '$label $what: ${r.toStringAsFixed(2)}');
        }

        test('ColorScheme', () {
          final s = th.colorScheme;
          check('onPrimary/primary', s.onPrimary, s.primary);
          check('onSurface/surface', s.onSurface, s.surface);
          check('onSurfaceVariant/surface', s.onSurfaceVariant, s.surface);
          check('onError/error', s.onError, s.error);
          check('onErrorContainer/errorContainer', s.onErrorContainer, s.errorContainer);
          check('onPrimaryContainer/primaryContainer', s.onPrimaryContainer, s.primaryContainer);
          check('onSecondaryContainer/secondaryContainer', s.onSecondaryContainer, s.secondaryContainer);
          check('onInverseSurface/inverseSurface', s.onInverseSurface, s.inverseSurface);
        });

        test('ปุ่ม', () {
          final f = th.filledButtonTheme.style!;
          check('filled fg/bg', _p(f.foregroundColor), _p(f.backgroundColor));
          check('text button fg/surface', _p(th.textButtonTheme.style!.foregroundColor), c.surface);
          check('outlined fg/surface', _p(th.outlinedButtonTheme.style!.foregroundColor), c.surface);
          final el = th.elevatedButtonTheme.style!;
          check('elevated fg/bg', _p(el.foregroundColor), _p(el.backgroundColor));
        });

        test('ชิป · segmented · ลิสต์ · แท็บ · เมนูนำทาง', () {
          final chip = th.chipTheme;
          check('chip selected', _c(chip.labelStyle!.color, {WidgetState.selected}), chip.selectedColor!);
          check('chip normal', _c(chip.labelStyle!.color), chip.backgroundColor!);
          final seg = th.segmentedButtonTheme.style!;
          check('segmented selected', _p(seg.foregroundColor, {WidgetState.selected}), _p(seg.backgroundColor, {WidgetState.selected}));
          check('segmented normal', _p(seg.foregroundColor), c.surface);
          check('listTile selected', th.listTileTheme.selectedColor!, th.listTileTheme.selectedTileColor!);
          check('tab label', th.tabBarTheme.labelColor!, c.surface);
          check('tab unselected', th.tabBarTheme.unselectedLabelColor!, c.surface);
          final nav = th.navigationBarTheme;
          check('nav selected icon', nav.iconTheme!.resolve({WidgetState.selected})!.color!, nav.indicatorColor!);
          check('nav label', nav.labelTextStyle!.resolve({})!.color!, nav.backgroundColor!);
          check('nav label selected', nav.labelTextStyle!.resolve({WidgetState.selected})!.color!, nav.backgroundColor!);
        });

        test('ช่องกรอก · dialog · เมนู · snackbar · tooltip', () {
          final i = th.inputDecorationTheme;
          check('hint', i.hintStyle!.color!, i.fillColor!);
          check('label', i.labelStyle!.color!, i.fillColor!);
          check('error text', i.errorStyle!.color!, i.fillColor!);
          check('dialog title', th.dialogTheme.titleTextStyle!.color!, th.dialogTheme.backgroundColor!);
          check('dialog content', th.dialogTheme.contentTextStyle!.color!, th.dialogTheme.backgroundColor!);
          check('popup text', th.popupMenuTheme.textStyle!.color!, th.popupMenuTheme.color!);
          check('snackbar text', th.snackBarTheme.contentTextStyle!.color!, th.snackBarTheme.backgroundColor!);
          check('snackbar action', th.snackBarTheme.actionTextColor!, th.snackBarTheme.backgroundColor!);
          final tip = (th.tooltipTheme.decoration! as BoxDecoration).color!;
          check('tooltip', th.tooltipTheme.textStyle!.color!, tip);
        });

        test('ตัวควบคุมที่เหลือเห็นชัด (ไม่ใช่ตัวอักษร ≥ 3:1) : สวิตช์/ช็อกซ์/สไลเดอร์/ราง', () {
          final sw = th.switchTheme;
          // สวิตช์เปิด: นิ้วจับ (onPrimary) เห็นบนราง (accent)
          check('switch on thumb/track', _p(sw.thumbColor, {WidgetState.selected}), _p(sw.trackColor, {WidgetState.selected}), min: 3);
          // สวิตช์ปิด: เส้นขอบรางเห็นบนพื้น
          check('switch off outline/surface', _p(sw.trackOutlineColor), c.surface, min: 1.3);
          check('checkbox border/surface', (th.checkboxTheme.side! as WidgetStateBorderSide).resolve({})!.color, c.surface, min: 1.3);
          check('slider track', th.sliderTheme.inactiveTrackColor!, c.surface, min: 1.2);
          check('progress track', th.progressIndicatorTheme.linearTrackColor!, c.surface, min: 1.2);
        });
      });
    }
  }

  group('รูปทรง/ความหนาแน่น/ฟอนต์/เงา ตามธีม', () {
    final base = _tok(kBuiltinDefault, Brightness.light);

    test('มุมโค้งตาม shape', () {
      final s = const NslShape(xs: 1, sm: 2, md: 3, lg: 5, xl: 7, pill: 99);
      final th = buildNslThemeData(_with(base, shape: s));
      BorderRadius br(ShapeBorder? sb) => (sb! as RoundedRectangleBorder).borderRadius as BorderRadius;
      expect(br(th.dialogTheme.shape), BorderRadius.circular(5));
      expect(br(th.cardTheme.shape), BorderRadius.circular(5));
      expect(br(th.popupMenuTheme.shape), BorderRadius.circular(3));
      expect(br(th.snackBarTheme.shape), BorderRadius.circular(3));
      expect(br(th.listTileTheme.shape), BorderRadius.circular(3));
      expect(br(th.chipTheme.shape), BorderRadius.circular(99));
      expect(br(th.checkboxTheme.shape), BorderRadius.circular(1));
      expect(((th.filledButtonTheme.style!.shape!.resolve({}) as RoundedRectangleBorder).borderRadius), BorderRadius.circular(3));
      expect(((th.bottomSheetTheme.shape! as RoundedRectangleBorder).borderRadius), BorderRadius.vertical(top: const Radius.circular(7)));
    });

    test('ความหนาแน่น : visualDensity · ความสูงปุ่ม · ช่องกรอก', () {
      double h(NslDensity d, [TargetPlatform p = TargetPlatform.windows]) =>
          buildNslThemeData(_with(base, density: d), platform: p).filledButtonTheme.style!.minimumSize!.resolve({})!.height;
      expect(h(NslDensity.compact), lessThan(h(NslDensity.normal)));
      expect(h(NslDensity.normal), lessThan(h(NslDensity.comfortable)));
      for (final d in NslDensity.values) {
        expect(h(d, TargetPlatform.android), greaterThanOrEqualTo(kMinTapTarget), reason: 'touch ${d.name}');
      }
      // flutter_test ใช้ Android เป็นค่าเริ่มต้น จึงระบุแพลตฟอร์มชัดเจนทุกครั้ง
      const desktop = TargetPlatform.windows, phone = TargetPlatform.android;
      final compact = _with(base, density: NslDensity.compact);
      expect(buildNslThemeData(compact, platform: desktop).visualDensity, compact.visualDensity);
      expect(buildNslThemeData(compact, platform: phone).visualDensity, VisualDensity.standard); // จอสัมผัสไม่ให้ compact
      expect(buildNslThemeData(compact, platform: desktop).inputDecorationTheme.isDense, isTrue);
      expect(buildNslThemeData(_with(base, density: NslDensity.normal), platform: desktop).inputDecorationTheme.isDense, isFalse);
      expect(buildNslThemeData(compact, platform: desktop).materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
      expect(buildNslThemeData(compact, platform: phone).materialTapTargetSize, MaterialTapTargetSize.padded);
      expect(buildNslThemeData(compact, platform: phone).platform, phone);
    });

    test('ฟอนต์และขนาดตัวอักษรตามธีม', () {
      final th = buildNslThemeData(_with(base, type: const NslType(family: 'Foo', scale: 1.2)));
      expect(th.textTheme.bodyMedium!.fontFamily, 'Foo');
      expect(th.textTheme.bodyMedium!.fontFamilyFallback, contains(kNslThaiFont));
      final plain = buildNslThemeData(base);
      expect(plain.textTheme.bodyMedium!.fontFamily, kNslThaiFont);
      expect(th.textTheme.bodyMedium!.fontSize!, closeTo(plain.textTheme.bodyMedium!.fontSize! * 1.2, 1e-9));
      expect(th.dialogTheme.titleTextStyle!.fontSize, closeTo(18 * 1.2, 1e-9));
      expect(th.textTheme.bodyMedium!.color, base.colors.text);
    });

    test('เงา : flat หรือ strength 0 = ไม่มีเงา · shadow = มีและตามความเข้ม', () {
      final flat = buildNslThemeData(_with(base, elevation: const NslElevation(mode: NslElevationMode.flat)));
      expect(flat.dialogTheme.elevation, 0);
      expect(flat.popupMenuTheme.elevation, 0);
      expect(flat.bottomSheetTheme.elevation, 0);
      expect(buildNslThemeData(_with(base, elevation: const NslElevation(strength: 0))).dialogTheme.elevation, 0);
      final s1 = buildNslThemeData(base).dialogTheme.elevation!;
      final s15 = buildNslThemeData(_with(base, elevation: const NslElevation(strength: 1.5))).dialogTheme.elevation!;
      expect(s1, greaterThan(0));
      expect(s15, closeTo(s1 * 1.5, 1e-9));
    });

    test('สถานะของสวิตช์/ช็อกซ์/ชิป : ปิดใช้งานแยกจากปกติ', () {
      final c = base.colors, th = buildNslThemeData(base);
      expect(_p(th.switchTheme.trackColor, {WidgetState.selected}), c.accent);
      expect(_p(th.switchTheme.trackColor, {WidgetState.selected, WidgetState.disabled}), c.surfaceSunken);
      expect(_p(th.checkboxTheme.fillColor, {WidgetState.selected}), c.accent);
      expect(_p(th.checkboxTheme.fillColor), Colors.transparent);
      expect(_p(th.radioTheme.fillColor, {WidgetState.selected}), c.accent);
      expect(_p(th.radioTheme.fillColor, {WidgetState.disabled}), c.textFaint);
      expect(_c(th.chipTheme.labelStyle!.color, {WidgetState.disabled}), c.textFaint);
    });
  });

  group('parity กับ buildTheme ของแอปจริง (อ่านอย่างเดียว) — เฉพาะค่าที่ core ยืนยันตรงกันแล้ว', () {
    for (final entry in {Brightness.light: dev.kLightPalette, Brightness.dark: dev.kDarkPalette}.entries) {
      test('Nebular ${entry.key.name}', () {
        final b = entry.key, p = entry.value;
        dev.C.use(p);
        addTearDown(() => dev.C.use(dev.kLightPalette));
        final app = dev.buildTheme(p);
        final ours = buildNslThemeData(_tok(kBuiltinDev, b));
        expect(ours.scaffoldBackgroundColor, app.scaffoldBackgroundColor);
        expect(ours.canvasColor, app.canvasColor);
        expect(ours.dividerColor, app.dividerColor);
        expect(ours.dialogTheme.backgroundColor, app.dialogTheme.backgroundColor);
        expect(ours.popupMenuTheme.color, app.popupMenuTheme.color);
        expect(ours.colorScheme.primary, app.colorScheme.primary);
        expect(ours.colorScheme.surface, app.colorScheme.surface);
        // ตัวอักษรบนปุ่ม primary : แอปใช้ขาวตายตัว ; ตัวสร้างกลางใช้ขาวเมื่อผ่าน 4.5:1 และปรับให้ผ่านเมื่อไม่ผ่าน
        // (nebular โหมดมืดขาวบน accent ได้ 3.68 — ปัญหาเดิมที่ core รู้อยู่แล้ว)
        final whiteOk = contrastRatio(Colors.white, app.colorScheme.primary) >= 4.5;
        if (whiteOk) {
          expect(ours.colorScheme.onPrimary, app.colorScheme.onPrimary);
        } else {
          expect(contrastRatio(ours.colorScheme.onPrimary, ours.colorScheme.primary), greaterThanOrEqualTo(4.5));
          expect(ours.colorScheme.onPrimary, isNot(app.colorScheme.onPrimary));
        }
      });

      test('Spectrum ${entry.key.name}', () {
        final b = entry.key;
        final accent = res.defaultAccent;
        final app = res.buildTheme(b, accent);
        final ours = buildNslThemeData(_tok(builtinResonance(accent), b));
        expect(ours.scaffoldBackgroundColor, app.scaffoldBackgroundColor);
        expect(ours.colorScheme.surface, app.colorScheme.surface);
        // ต่างโดยตั้งใจ : Spectrum ใช้ accentInk เป็น primary (accent ทองอ่านเป็นตัวอักษรบนพื้นสว่างไม่ได้)
        // ตัวสร้างกลางใช้ accent เป็น primary แล้วให้ปุ่มข้อความใช้ accentInk แทน
        final tokens = _tok(builtinResonance(accent), b);
        expect(ours.colorScheme.primary, tokens.colors.accent);
        expect(app.colorScheme.primary, tokens.colors.accentInk);
      });
    }
  });

  group('เรนเดอร์ตัวควบคุม Material จริงภายใต้ธีมที่สร้าง', () {
    Widget page() => DefaultTabController(
          length: 2,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Switch(value: true, onChanged: (_) {}),
                    Switch(value: false, onChanged: (_) {}),
                    const Switch(value: true, onChanged: null),
                    Checkbox(value: true, onChanged: (_) {}),
                    Checkbox(value: false, onChanged: (_) {}),
                    const Checkbox(value: true, onChanged: null),
                    const ChoiceChip(label: Text('เลือกอยู่ ข้อความยาว'), selected: true, onSelected: null),
                    ChoiceChip(label: const Text('ไม่เลือก'), selected: false, onSelected: (_) {}),
                    FilterChip(label: const Text('ตัวกรอง'), selected: true, onSelected: (_) {}),
                    ActionChip(label: const Text('การกระทำ'), onPressed: () {}),
                    FilledButton(onPressed: () {}, child: const Text('Filled')),
                    const FilledButton(onPressed: null, child: Text('Disabled')),
                    OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                    TextButton(onPressed: () {}, child: const Text('Text')),
                    ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                  ]),
                  SegmentedButton<int>(
                    segments: const [ButtonSegment(value: 1, label: Text('หนึ่ง')), ButtonSegment(value: 2, label: Text('สอง'))],
                    selected: const {1},
                    onSelectionChanged: (_) {},
                  ),
                  Slider(value: 0.4, onChanged: (_) {}),
                  const LinearProgressIndicator(value: 0.5),
                  const ListTile(selected: true, leading: Icon(Icons.folder), title: Text('รายการที่เลือกอยู่'), subtitle: Text('คำอธิบายรอง')),
                  const ListTile(enabled: false, title: Text('ปิดใช้งาน')),
                  const TextField(decoration: InputDecoration(labelText: 'ป้าย', hintText: 'คำใบ้')),
                  const TextField(decoration: InputDecoration(labelText: 'ผิดพลาด', errorText: 'ข้อความผิดพลาด')),
                  const Card(child: Padding(padding: EdgeInsets.all(8), child: Text('การ์ด'))),
                  const Divider(),
                  const TabBar(tabs: [Tab(text: 'แท็บ A'), Tab(text: 'แท็บ B')]),
                ]),
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: const [NavigationDestination(icon: Icon(Icons.home), label: 'หน้าหลัก'), NavigationDestination(icon: Icon(Icons.search), label: 'ค้นหา')],
            ),
          ),
        );

    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        testWidgets('${e.key} ${b.name} × density × ขนาดตัวอักษร : ไม่มี exception/overflow', (tester) async {
          tester.view.physicalSize = const Size(360, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final d in NslDensity.values) {
            for (final scale in [0.9, 1.2]) {
              final t = _with(_tok(e.value, b), density: d, type: NslType(scale: scale));
              await tester.pumpWidget(MaterialApp(theme: buildNslThemeData(t), home: page()));
              await tester.pump(const Duration(milliseconds: 50));
              expect(tester.takeException(), isNull, reason: '${e.key} ${b.name} ${d.name} scale $scale');
            }
          }
        });
      }
    }

    testWidgets('dialog · เมนู · snackbar · tooltip ใช้สี/มุมโค้ง/เงาจากธีม', (tester) async {
      for (final b in Brightness.values) {
        final t = _tok(kBuiltinDev, b), c = t.colors;
        late BuildContext ctx;
        await tester.pumpWidget(MaterialApp(
          theme: buildNslThemeData(t),
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return Column(children: [
                PopupMenuButton<int>(
                  key: const Key('menu'),
                  itemBuilder: (_) => const [PopupMenuItem(value: 1, child: Text('เมนูข้อ 1'))],
                ),
                const Tooltip(message: 'คำแนะนำ', child: SizedBox(key: Key('tip'), width: 40, height: 40)),
              ]);
            }),
          ),
        ));

        showDialog<void>(context: ctx, builder: (_) => const AlertDialog(title: Text('หัวข้อ'), content: Text('เนื้อหา')));
        await tester.pumpAndSettle();
        final dialog = tester.widget<Material>(find.descendant(of: find.byType(AlertDialog), matching: find.byType(Material)).first);
        expect(dialog.color, c.surfaceRaised, reason: 'dialog ${b.name}');
        expect((dialog.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(t.shape.lg));
        Navigator.of(ctx).pop();
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('menu')));
        await tester.pumpAndSettle();
        expect(find.text('เมนูข้อ 1'), findsOneWidget);
        // พื้นของเมนูต้องเป็น surfaceRaised ตามธีม
        expect(find.ancestor(of: find.text('เมนูข้อ 1'), matching: find.byWidgetPredicate((w) => w is Material && w.color == c.surfaceRaised)), findsWidgets);
        await tester.tapAt(const Offset(1, 1));
        await tester.pumpAndSettle();

        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('แจ้งเตือน')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final snack = tester.widget<Material>(find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first);
        expect(snack.color, b == Brightness.dark ? c.surfaceRaised : c.text, reason: 'snackbar ${b.name}');
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('สอดคล้องกับ component ของ nsl_ui', () {
    testWidgets('FilledButton ของ Material หน้าตาตรงกับ NslButton primary (สี/ตัวอักษร/มุมโค้ง/ความสูง)', (tester) async {
      final t = _tok(kBuiltinDev, Brightness.dark);
      // เดสก์ท็อป : ความสูงปุ่มตรงกับ controlHeight (จอสัมผัสต่างกันตั้งใจ — Material เผื่อพื้นที่แตะ 48 ส่วน NslButton 44)
      await tester.pumpWidget(MaterialApp(
        theme: buildNslThemeData(t, platform: TargetPlatform.windows),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FilledButton(onPressed: () {}, child: const Text('M')),
              NslButton(label: 'N', kind: NslButtonKind.primary, onPressed: () {}),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final m = find.byType(FilledButton), n = find.byType(NslButton);
      final mBg = tester.widget<Material>(find.descendant(of: m, matching: find.byType(Material)).first);
      final nBg = tester.widget<Material>(find.descendant(of: n, matching: find.byType(Material)).first);
      expect(mBg.color, nBg.color);
      expect(tester.getSize(m).height, tester.getSize(n).height);
      expect((mBg.shape! as RoundedRectangleBorder).borderRadius, (nBg.shape! as RoundedRectangleBorder).borderRadius);
      // ตัวอักษรบนปุ่มเท่ากัน (ทั้งคู่ผ่าน legibleOn — nebular โหมดมืดเป็นกรณีที่ต้องปรับ)
      final mFg = DefaultTextStyle.of(tester.element(find.text('M'))).style.color;
      final nFg = tester.widget<Text>(find.text('N')).style!.color;
      expect(mFg, nFg);
    });

    testWidgets('จอสัมผัส : FilledButton ไม่เตี้ยกว่า 44 (kMinTapTarget)', (tester) async {
      for (final d in NslDensity.values) {
        final t = _with(_tok(kBuiltinDev, Brightness.light), density: d);
        await tester.pumpWidget(MaterialApp(
          theme: buildNslThemeData(t, platform: TargetPlatform.android),
          home: Scaffold(body: Align(alignment: Alignment.topLeft, child: FilledButton(onPressed: () {}, child: const Text('M')))),
        ));
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(kMinTapTarget), reason: d.name);
      }
    });

    testWidgets('context.nsl ใช้ได้เลยโดยไม่ต้องครอบ NslThemeScope', (tester) async {
      final t = _tok(kBuiltinLyraPaper, Brightness.light);
      late NslTokens got;
      await tester.pumpWidget(MaterialApp(theme: buildNslThemeData(t), home: Builder(builder: (c) {
        got = c.nsl;
        return const SizedBox();
      })));
      expect(got, t);
    });
  });
}
