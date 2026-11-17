import 'package:flutter/material.dart';

/// พื้นผิวที่กดได้ของ component (ใช้ภายใน nsl_ui — ไม่ export)
///
/// รวมสิ่งที่ปุ่มทุกแบบต้องมีเหมือนกัน : hover/focus/pressed, วงโฟกัสคีย์บอร์ดที่เห็นชัด,
/// Semantics (button/enabled/selected/label), เคอร์เซอร์ และพื้นที่แตะขั้นต่ำ
/// สี/มุมโค้ง/ขนาดทั้งหมดรับจากผู้เรียก (ซึ่งอ่านจาก token) — ไฟล์นี้ไม่มีค่าตายตัว
class NslPressable extends StatefulWidget {
  const NslPressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.radius,
    required this.background,
    required this.overlay,
    required this.ring,
    required this.semanticLabel,
    required this.minHeight,
    this.minWidth = 0,
    this.border,
    this.selected,
    this.onLongPress,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;

  /// null = ปิดใช้งาน
  final VoidCallback? onTap;

  /// กดค้าง (ไม่บังคับ) — โปรแกรมอ่านหน้าจอได้ action longPress ด้วย
  final VoidCallback? onLongPress;
  final double radius;
  final Color background;

  /// สีซ้อนตอน hover/focus/pressed
  final Color overlay;

  /// สีวงโฟกัสคีย์บอร์ด
  final Color ring;
  final Color? border;
  final String semanticLabel;
  final bool? selected;
  final double minHeight, minWidth;
  final EdgeInsetsGeometry padding;

  @override
  State<NslPressable> createState() => _NslPressableState();
}

class _NslPressableState extends State<NslPressable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final shape = BorderRadius.circular(widget.radius);
    return Semantics(
      button: true,
      enabled: enabled,
      focusable: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      // excludeSemantics ตัด action ของ InkWell ทิ้ง → ต้องประกาศ onTap เองไม่งั้นโปรแกรมอ่านหน้าจอสั่งแตะไม่ได้
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.minHeight, minWidth: widget.minWidth),
        child: Material(
          color: widget.background,
          shape: RoundedRectangleBorder(
            borderRadius: shape,
            side: widget.border == null ? BorderSide.none : BorderSide(color: widget.border!),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: shape,
            hoverColor: widget.overlay,
            focusColor: widget.overlay,
            highlightColor: widget.overlay,
            splashColor: widget.overlay,
            onFocusChange: (v) => setState(() => _focused = v),
            // ไม่ใช้ Container(alignment:) เพราะมันขยายเต็มพื้นที่เมื่อพ่อให้ความสูงแบบหลวม — Center(heightFactor: 1) พอดีกับเนื้อหา
            // (ความสูงขั้นต่ำมาจาก ConstrainedBox ด้านบน) ; วงโฟกัสวาดทับด้านหน้า
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: _focused ? BoxDecoration(borderRadius: shape, border: Border.all(color: widget.ring, width: 2)) : const BoxDecoration(),
              child: Padding(
                padding: widget.padding,
                child: Center(widthFactor: 1, heightFactor: 1, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
