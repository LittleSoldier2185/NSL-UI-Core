import 'package:flutter/material.dart';

import '../appearance/accent_presets.dart';
import '../appearance/appearance.dart';
import '../format/nslt_codec.dart';

/// ข้อความของ [NslAppearancePanel] (แอปส่งภาษาของตัวเองเข้ามาได้ — nsl_ui ไม่ผูกกับระบบแปลภาษาใด)
class NslAppearanceStrings {
  const NslAppearanceStrings({
    required this.english,
    required this.mode,
    required this.system,
    required this.light,
    required this.dark,
    required this.accent,
    required this.custom,
    required this.reset,
    required this.hex,
    required this.invalidHex,
    required this.hue,
    required this.saturation,
    required this.lightness,
  });

  /// true = ใช้ชื่อ preset ภาษาอังกฤษ
  final bool english;
  final String mode, system, light, dark, accent, custom, reset, hex, invalidHex, hue, saturation, lightness;

  static const th = NslAppearanceStrings(
    english: false,
    mode: 'โหมด',
    system: 'ตามระบบ',
    light: 'สว่าง',
    dark: 'มืด',
    accent: 'สีเน้น',
    custom: 'สีกำหนดเอง',
    reset: 'คืนค่าตามธีม',
    hex: 'รหัสสี (#RRGGBB)',
    invalidHex: 'รหัสสีไม่ถูกต้อง',
    hue: 'เฉดสี',
    saturation: 'ความอิ่มสี',
    lightness: 'ความสว่าง',
  );

  static const en = NslAppearanceStrings(
    english: true,
    mode: 'Mode',
    system: 'System',
    light: 'Light',
    dark: 'Dark',
    accent: 'Accent colour',
    custom: 'Custom colour',
    reset: 'Reset to theme',
    hex: 'Colour code (#RRGGBB)',
    invalidHex: 'Invalid colour code',
    hue: 'Hue',
    saturation: 'Saturation',
    lightness: 'Lightness',
  );
}

/// แผงปรับแต่งแบบ lite ที่ทุกแอปใช้ได้: โหมด สว่าง/มืด/ตามระบบ + accent (preset หรือสีกำหนดเอง) + คืนค่า
///
/// เป็น widget ล้วน ๆ (ไม่พึ่ง `file_picker` หรือ state management ใด) — แอปรับ [value] จาก
/// `NslThemeController.appearance` แล้วส่งผลกลับด้วย [onChanged] → `controller.setAppearance`
/// การปรับที่ลึกกว่านี้ (สีรายตัว, มุมโค้ง, เงา) ทำที่เว็บ NSL Palette
class NslAppearancePanel extends StatefulWidget {
  const NslAppearancePanel({
    super.key,
    required this.value,
    required this.onChanged,
    this.presets = kAccentPresets,
    this.strings = NslAppearanceStrings.th,
  });

  final NslAppearance value;
  final ValueChanged<NslAppearance> onChanged;
  final List<NslAccentPreset> presets;
  final NslAppearanceStrings strings;

  @override
  State<NslAppearancePanel> createState() => _NslAppearancePanelState();
}

class _NslAppearancePanelState extends State<NslAppearancePanel> {
  static const _fallbackCustom = Color(0xFF7B58D6);

  late final TextEditingController _hex;
  bool _editorOpen = false;
  bool _hexBad = false;

  @override
  void initState() {
    super.initState();
    _hex = TextEditingController(text: _hexOf(widget.value.customAccent ?? _fallbackCustom));
    _editorOpen = widget.value.presetId == null && widget.value.customAccent != null;
  }

  @override
  void didUpdateWidget(NslAppearancePanel old) {
    super.didUpdateWidget(old);
    final c = widget.value.customAccent;
    // ค่าเปลี่ยนจากภายนอก (เช่น ล้างค่า / โหลดใหม่) → ซิงก์ช่องรหัสสี ยกเว้นผู้ใช้กำลังพิมพ์ค่าที่ตรงกันอยู่แล้ว
    if (c != null && c != old.value.customAccent && _parse(_hex.text) != c) {
      _hex.text = _hexOf(c);
      _hexBad = false;
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  static String _hexOf(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static Color? _parse(String t) {
    final s = t.trim();
    final c = parseHexColor(s.startsWith('#') ? s : '#$s');
    return c == null || c.a != 1.0 ? null : c;
  }

  void _setCustom(Color c) {
    _hex.text = _hexOf(c);
    setState(() => _hexBad = false);
    widget.onChanged(widget.value.withCustom(c));
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.strings;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final v = widget.value;
    final cs = Theme.of(context).colorScheme;
    final custom = v.customAccent;
    final hsl = HSLColor.fromColor(custom ?? _fallbackCustom);

    Widget swatch({required Key key, required Color color, required bool selected, required String label, required VoidCallback onTap, Widget? child}) {
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: InkResponse(
            key: key,
            onTap: onTap,
            radius: 24,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: selected ? cs.onSurface : cs.outlineVariant, width: selected ? 3 : 1),
              ),
              child: child ?? (selected ? Icon(Icons.check, size: 20, color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black) : null),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(st.mode, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<NslModeChoice>(
          key: const ValueKey('nsl-mode'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: NslModeChoice.system, label: Text(st.system, key: const ValueKey('nsl-mode-system'))),
            ButtonSegment(value: NslModeChoice.light, label: Text(st.light, key: const ValueKey('nsl-mode-light'))),
            ButtonSegment(value: NslModeChoice.dark, label: Text(st.dark, key: const ValueKey('nsl-mode-dark'))),
          ],
          selected: {v.mode},
          onSelectionChanged: (s) => widget.onChanged(v.withMode(s.first)),
        ),
        const SizedBox(height: 20),
        Text(st.accent, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final p in widget.presets)
              swatch(
                key: ValueKey('nsl-preset-${p.id}'),
                color: p.set(dark).$1,
                selected: v.presetId == p.id,
                label: st.english ? p.nameEn : p.nameTh,
                onTap: () => widget.onChanged(v.withPreset(p.id)),
              ),
            swatch(
              key: const ValueKey('nsl-custom'),
              color: custom == null ? cs.surfaceContainerHighest : (v.accentSet(dark)?.$1 ?? custom),
              selected: v.presetId == null && custom != null,
              label: st.custom,
              onTap: () => setState(() => _editorOpen = !_editorOpen), // แค่เปิด/ปิดตัวแก้ ยังไม่เปลี่ยนสีจนกว่าผู้ใช้จะแก้
              child: custom == null || v.presetId != null ? Icon(Icons.palette_outlined, size: 20, color: cs.onSurface) : null,
            ),
          ],
        ),
        if (_editorOpen) ...[
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('nsl-hex'),
            controller: _hex,
            decoration: InputDecoration(labelText: st.hex, errorText: _hexBad ? st.invalidHex : null, isDense: true, border: const OutlineInputBorder()),
            onChanged: (t) {
              final c = _parse(t);
              if (c == null) {
                setState(() => _hexBad = true);
              } else {
                setState(() => _hexBad = false);
                widget.onChanged(widget.value.withCustom(c));
              }
            },
          ),
          const SizedBox(height: 8),
          _slider(st.hue, hsl.hue, 0, 360, (x) => _setCustom(hsl.withHue(x).toColor()), const ValueKey('nsl-hue')),
          _slider(st.saturation, hsl.saturation, 0, 1, (x) => _setCustom(hsl.withSaturation(x).toColor()), const ValueKey('nsl-sat')),
          _slider(st.lightness, hsl.lightness, 0, 1, (x) => _setCustom(hsl.withLightness(x).toColor()), const ValueKey('nsl-light')),
        ],
        if (v.hasAccent) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey('nsl-reset'),
            onPressed: () => widget.onChanged(v.clearedAccent()),
            icon: const Icon(Icons.restart_alt),
            label: Text(st.reset),
          ),
        ],
      ],
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, Key key) => Row(
        children: [
          SizedBox(width: 96, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Slider(key: key, value: value.clamp(min, max).toDouble(), min: min, max: max, onChanged: onChanged)),
        ],
      );
}
