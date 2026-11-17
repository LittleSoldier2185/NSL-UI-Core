import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format/nslt_codec.dart';
import '../theme/adjust.dart';
import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';

/// ข้อความของตัวเลือกสี (ค่าเริ่มต้นเป็นภาษาไทย — แอปส่งชุดอื่นได้)
class NslColorPickerStrings {
  const NslColorPickerStrings({
    required this.hexLabel,
    required this.hexInvalid,
    required this.areaLabel,
    required this.hueLabel,
    required this.presetLabel,
  });

  /// ป้ายของช่องรหัสสี
  final String hexLabel;

  /// ข้อความเมื่อรหัสสีที่พิมพ์ไม่ถูกต้อง
  final String hexInvalid;

  /// พื้นที่เลือกความสด (แนวนอน) + ความสว่าง (แนวตั้ง)
  final String areaLabel;

  /// แถบเฉดสี
  final String hueLabel;

  /// สีสำเร็จรูป (ตามด้วยรหัสสี)
  final String presetLabel;

  static const th = NslColorPickerStrings(
    hexLabel: 'รหัสสี (HEX)',
    hexInvalid: 'รหัสสีไม่ถูกต้อง (เช่น 0F766E)',
    areaLabel: 'ความสดและความสว่าง',
    hueLabel: 'เฉดสี',
    presetLabel: 'สี',
  );

  static const en = NslColorPickerStrings(
    hexLabel: 'Hex colour',
    hexInvalid: 'Invalid colour code (e.g. 0F766E)',
    areaLabel: 'Saturation and brightness',
    hueLabel: 'Hue',
    presetLabel: 'Colour',
  );
}

/// ตัวเลือกสีอิสระ : พื้นที่ความสด/ความสว่าง + แถบเฉดสี + ช่องรหัส HEX + สีสำเร็จรูป (ไม่บังคับ)
///
/// รวมของที่แอปเขียนซ้ำ (กล่องเลือกสีของ Nebular, แผ่นเลือกสีของ Orbit, ช่อง hex ของ Launcher) เป็นส่วนเนื้อหาเดียว —
/// **ไม่มีปุ่มตกลง/ยกเลิก** : แอปครอบด้วย dialog / bottom sheet ของตัวเอง แล้วรับค่าจาก [onChanged]
///
/// - สีทึบเท่านั้น (ไม่มี alpha) ; [onChanged] ถูกเรียกทุกครั้งที่ผู้ใช้เปลี่ยนสี (ลาก, พิมพ์ hex ที่ถูกต้อง, แตะสีสำเร็จรูป)
/// - เปลี่ยน [color] จากภายนอกได้ (ตัวเลือกจะตามไป) ยกเว้นเป็นสีเดียวกับที่เลือกอยู่แล้ว
/// - ใช้คีย์บอร์ดได้ : โฟกัสที่พื้นที่สี → ลูกศรซ้าย/ขวา = ความสด, ขึ้น/ลง = ความสว่าง ; โฟกัสที่แถบเฉดสี → ซ้าย/ขวา (Shift = ก้าวละ 10°)
/// - โปรแกรมอ่านหน้าจอ : แถบเฉดสีเป็น slider ที่เพิ่ม/ลดได้ ; พื้นที่สีบอกค่า % และเพิ่ม/ลดความสด ; ใช้ช่อง HEX ตั้งสีใดก็ได้
class NslColorPicker extends StatefulWidget {
  const NslColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
    this.presets = const [],
    this.strings = NslColorPickerStrings.th,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final List<Color> presets;
  final NslColorPickerStrings strings;

  @override
  State<NslColorPicker> createState() => _NslColorPickerState();
}

class _NslColorPickerState extends State<NslColorPicker> {
  late HSVColor _hsv = HSVColor.fromColor(_opaque(widget.color));
  late final TextEditingController _hexCtl = TextEditingController(text: _hexOf(_hsv.toColor()));
  bool _hexBad = false;

  static Color _opaque(Color c) => c.withValues(alpha: 1);
  static String _hexOf(Color c) => (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  /// รับ `abc`, `#abc`, `0F766E`, `#0F766E` ; ไม่รับสีโปร่ง (8 หลัก)
  static Color? _parse(String text) {
    var s = text.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 3) s = s.split('').map((ch) => ch + ch).join();
    final c = parseHexColor('#$s');
    return c == null || c.a != 1.0 ? null : c;
  }

  @override
  void didUpdateWidget(NslColorPicker old) {
    super.didUpdateWidget(old);
    final c = _opaque(widget.color);
    if (c != _opaque(old.color) && c != _hsv.toColor()) {
      _hsv = HSVColor.fromColor(c);
      _hexCtl.text = _hexOf(c);
      _hexBad = false;
    }
  }

  @override
  void dispose() {
    _hexCtl.dispose();
    super.dispose();
  }

  /// [fromHex] = มาจากการพิมพ์ในช่อง hex (อย่าเขียนทับสิ่งที่ผู้ใช้กำลังพิมพ์)
  void _set(HSVColor v, {bool fromHex = false}) {
    final before = _hsv.toColor();
    setState(() {
      _hsv = v;
      _hexBad = false;
      if (!fromHex) _hexCtl.text = _hexOf(v.toColor());
    });
    final after = v.toColor();
    if (after != before) widget.onChanged(after);
  }

  void _onHex(String text) {
    final c = _parse(text);
    if (c == null) {
      setState(() => _hexBad = text.trim().isNotEmpty);
      return;
    }
    // รักษา hue/saturation เดิมเมื่อสีเทา/ดำ (HSV ของสีนั้นไม่มี hue) — ใช้ค่าที่คำนวณจากสีจริงเสมอ
    _set(HSVColor.fromColor(c), fromHex: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors, st = widget.strings;
    final touch = context.nslTouch;
    final color = _hsv.toColor();
    final gap = t.gap;
    final swatch = touch ? kMinTapTarget : gap * 3.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ตัวอย่างสี + ค่า hex (ตัวอักษรเลือกสีที่อ่านออกบนสีนั้น)
        Container(
          height: t.controlHeight(touch: touch),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(t.shape.md), border: Border.all(color: c.border)),
          child: Text('#${_hexOf(color)}', style: t.textStyle(14, weight: FontWeight.w600, color: t.legibleOn(c.text, color))),
        ),
        SizedBox(height: gap),
        _DragArea(
          label: st.areaLabel,
          semanticValue: '${(_hsv.saturation * 100).round()}%, ${(_hsv.value * 100).round()}%',
          increasedValue: '${((_hsv.saturation + 0.05).clamp(0.0, 1.0) * 100).round()}%, ${(_hsv.value * 100).round()}%',
          decreasedValue: '${((_hsv.saturation - 0.05).clamp(0.0, 1.0) * 100).round()}%, ${(_hsv.value * 100).round()}%',
          height: gap * 20,
          radius: t.shape.md,
          touch: touch,
          onPoint: (x, y) => _set(_hsv.withSaturation(x).withValue(1 - y)),
          onKey: (dx, dy, big) {
            final step = big ? 0.1 : 0.02;
            _set(_hsv.withSaturation((_hsv.saturation + dx * step).clamp(0.0, 1.0)).withValue((_hsv.value - dy * step).clamp(0.0, 1.0)));
          },
          onIncrease: () => _set(_hsv.withSaturation((_hsv.saturation + 0.05).clamp(0.0, 1.0))),
          onDecrease: () => _set(_hsv.withSaturation((_hsv.saturation - 0.05).clamp(0.0, 1.0))),
          painter: _AreaPainter(_hsv, thumbRing: c.surface, thumbEdge: c.text),
        ),
        SizedBox(height: gap * 1.5),
        _DragArea(
          label: st.hueLabel,
          semanticValue: '${_hsv.hue.round()}°',
          increasedValue: '${(_hsv.hue + 5).clamp(0.0, 360.0).round()}°',
          decreasedValue: '${(_hsv.hue - 5).clamp(0.0, 360.0).round()}°',
          height: gap * 2.5,
          radius: t.shape.pill,
          touch: touch,
          horizontalOnly: true,
          onPoint: (x, _) => _set(_hsv.withHue((x * 360).clamp(0.0, 360.0))),
          onKey: (dx, dy, big) => _set(_hsv.withHue((_hsv.hue + dx * (big ? 10 : 2)).clamp(0.0, 360.0))),
          onIncrease: () => _set(_hsv.withHue((_hsv.hue + 5).clamp(0.0, 360.0))),
          onDecrease: () => _set(_hsv.withHue((_hsv.hue - 5).clamp(0.0, 360.0))),
          painter: _HuePainter(_hsv.hue, thumbRing: c.surface, thumbEdge: c.text),
        ),
        SizedBox(height: gap * 1.5),
        TextField(
          controller: _hexCtl,
          maxLength: 7,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]'))],
          decoration: InputDecoration(
            isDense: true,
            labelText: st.hexLabel,
            prefixText: '#',
            counterText: '',
            errorText: _hexBad ? st.hexInvalid : null,
          ),
          onChanged: _onHex,
        ),
        if (widget.presets.isNotEmpty) ...[
          SizedBox(height: gap * 1.5),
          Wrap(spacing: gap, runSpacing: gap, children: [
            for (final p in widget.presets)
              _Swatch(
                color: _opaque(p),
                size: swatch,
                selected: _opaque(p) == color,
                label: '${st.presetLabel} #${_hexOf(p)}',
                onTap: () => _set(HSVColor.fromColor(_opaque(p))),
              ),
          ]),
        ],
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.size, required this.selected, required this.label, required this.onTap});
  final Color color;
  final double size;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: size * 0.7,
          focusColor: c.hover,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              // วงที่เลือกใช้ text (ตัดกับพื้นเสมอ) ; ปกติใช้ border
              border: Border.all(color: selected ? c.text : c.border, width: selected ? 3 : 1),
            ),
          ),
        ),
      ),
    );
  }
}

/// พื้นที่ลาก/คีย์บอร์ดที่ส่งตำแหน่ง 0..1 ; ใช้ทั้งพื้นที่ SV และแถบเฉดสี
class _DragArea extends StatefulWidget {
  const _DragArea({
    required this.label,
    required this.semanticValue,
    required this.increasedValue,
    required this.decreasedValue,
    required this.height,
    required this.radius,
    required this.touch,
    required this.onPoint,
    required this.onKey,
    required this.onIncrease,
    required this.onDecrease,
    required this.painter,
    this.horizontalOnly = false,
  });

  final String label;
  final String semanticValue;
  final String increasedValue;
  final String decreasedValue;
  final double height;
  final double radius;
  final bool touch;
  final bool horizontalOnly;
  final void Function(double x, double y) onPoint;
  final void Function(double dx, double dy, bool big) onKey;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final CustomPainter painter;

  @override
  State<_DragArea> createState() => _DragAreaState();
}

class _DragAreaState extends State<_DragArea> {
  bool _focused = false;

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final big = HardwareKeyboard.instance.isShiftPressed;
    double dx = 0, dy = 0;
    if (k == LogicalKeyboardKey.arrowLeft) {
      dx = -1;
    } else if (k == LogicalKeyboardKey.arrowRight) {
      dx = 1;
    } else if (!widget.horizontalOnly && k == LogicalKeyboardKey.arrowUp) {
      dy = -1;
    } else if (!widget.horizontalOnly && k == LogicalKeyboardKey.arrowDown) {
      dy = 1;
    } else {
      return KeyEventResult.ignored;
    }
    widget.onKey(dx, dy, big);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final h = widget.touch && widget.height < kMinTapTarget ? kMinTapTarget : widget.height;
    return Semantics(
      slider: true,
      focusable: true,
      label: widget.label,
      value: widget.semanticValue,
      increasedValue: widget.increasedValue,
      decreasedValue: widget.decreasedValue,
      onIncrease: widget.onIncrease,
      onDecrease: widget.onDecrease,
      excludeSemantics: true,
      child: Focus(
        onKeyEvent: _key,
        onFocusChange: (v) => setState(() => _focused = v),
        child: LayoutBuilder(builder: (_, box) {
          void at(Offset o) => widget.onPoint((o.dx / box.maxWidth).clamp(0.0, 1.0), (o.dy / h).clamp(0.0, 1.0));
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (d) => at(d.localPosition),
            onPanUpdate: (d) => at(d.localPosition),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(color: _focused ? c.accent : c.border, width: _focused ? 2 : 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.radius),
                child: SizedBox(height: h, width: double.infinity, child: CustomPaint(painter: widget.painter)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// สีล้วนจากแบบจำลอง HSV (ไม่ใช่สีของธีม) — ขาว/ดำ ของพื้นที่เลือกสีต้องเป็นขาว/ดำจริงเสมอ
final Color _white = HSVColor.fromAHSV(1, 0, 0, 1).toColor();
final Color _black = HSVColor.fromAHSV(1, 0, 0, 0).toColor();

void _thumb(Canvas canvas, Offset center, double r, Color fill, Color ring, Color edge) {
  canvas.drawCircle(center, r, Paint()..color = fill);
  canvas.drawCircle(center, r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = ring);
  canvas.drawCircle(center, r + 1.2, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = edge);
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.hsv, {required this.thumbRing, required this.thumbEdge});
  final HSVColor hsv;
  final Color thumbRing, thumbEdge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pure = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: [_white, pure]).createShader(rect));
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, _black]).createShader(rect));
    _thumb(canvas, Offset(hsv.saturation * size.width, (1 - hsv.value) * size.height), 9, hsv.toColor(), thumbRing, thumbEdge);
  }

  @override
  bool shouldRepaint(_AreaPainter o) => o.hsv != hsv || o.thumbRing != thumbRing || o.thumbEdge != thumbEdge;
}

class _HuePainter extends CustomPainter {
  _HuePainter(this.hue, {required this.thumbRing, required this.thumbEdge});
  final double hue;
  final Color thumbRing, thumbEdge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: [for (var i = 0; i <= 6; i++) HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor()]).createShader(rect));
    final r = size.height / 2 - 1.5;
    final x = (hue / 360 * size.width).clamp(r + 2, size.width - r - 2);
    _thumb(canvas, Offset(x, size.height / 2), r, HSVColor.fromAHSV(1, hue, 1, 1).toColor(), thumbRing, thumbEdge);
  }

  @override
  bool shouldRepaint(_HuePainter o) => o.hue != hue || o.thumbRing != thumbRing || o.thumbEdge != thumbEdge;
}
