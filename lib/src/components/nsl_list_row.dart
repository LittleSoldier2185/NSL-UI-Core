import 'package:flutter/material.dart';

import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';
import 'pressable.dart';

/// แถวรายการมาตรฐาน : [leading] + ชื่อ + ข้อความรอง + [trailing] พร้อมสถานะ "เลือกอยู่" และ "กำลังใช้งาน"
///
/// เป็นโครงเดียวกับที่แอปเขียนซ้ำ (แถวเพลง/ไฟล์/รายการ/ธุรกรรม) — ส่วนที่ผูกโดเมน (ภาพปก, ข้อมูลเพลง) ให้แอปประกอบเอง
/// แล้วส่งเข้า [leading]/[trailing]/[title]/[subtitle]
///
/// - [selected] : แถวถูกเลือก (เช่น โหมดเลือกหลายรายการ, รายการที่เปิดอยู่ในรายละเอียด) — พื้น `selected`
/// - [active] : แถวกำลังถูกใช้งาน (เช่น เพลงที่กำลังเล่น) — พื้น `hover` และชื่อสี accent
/// - [onTap] เป็น null = แถวแสดงผลอย่างเดียว (ไม่ใช่ปุ่ม ไม่มี hover/โฟกัส)
/// - [trailing] ของแถวที่กดได้อยู่นอกพื้นที่กดของแถว : ใส่ปุ่มของตัวเองได้ (เมนู ⋮) โดยโปรแกรมอ่านหน้าจอยังเห็นและกดแล้วไม่ไปเรียก [onTap]
class NslListRow extends StatelessWidget {
  const NslListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.active = false,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final bool active;
  final VoidCallback? onTap;

  /// กดค้าง (ไม่บังคับ ; ใช้ได้เมื่อมี [onTap])
  final VoidCallback? onLongPress;

  /// ไม่ระบุ = "ชื่อ, ข้อความรอง"
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final bg = selected ? c.selected : (active ? c.hover : Colors.transparent);
    final emphasised = selected || active;
    final titleColor = active ? t.legibleOn(c.accentInk, bg) : t.legibleOn(c.text, bg);
    final subColor = t.legibleOn(c.textMuted, bg);
    final minH = t.controlHeight(touch: context.nslTouch) + t.gap * 1.5;

    final label = semanticLabel ?? (subtitle == null ? title : '$title, $subtitle');
    final radius = t.shape.md;
    final main = Row(children: [
      if (leading != null) ...[leading!, SizedBox(width: t.gap * 1.5)],
      Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textStyle(15, weight: emphasised ? FontWeight.w600 : FontWeight.w500, color: titleColor)),
          if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textStyle(13, color: subColor)),
        ]),
      ),
    ]);
    final padding = EdgeInsets.symmetric(horizontal: t.gap * 1.5, vertical: t.gap * 0.75);

    if (onTap == null) {
      return Semantics(
        container: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Container(
          constraints: BoxConstraints(minHeight: minH),
          padding: padding,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
          alignment: Alignment.centerLeft,
          child: Row(children: [Expanded(child: main), if (trailing != null) ...[SizedBox(width: t.gap * 1.5), trailing!]]),
        ),
      );
    }
    final pressable = NslPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      radius: radius,
      background: trailing == null ? bg : Colors.transparent,
      overlay: c.hover,
      ring: c.accent,
      semanticLabel: label,
      selected: selected,
      minHeight: minH,
      padding: trailing == null ? padding : padding.copyWith(right: 0),
      child: main,
    );
    if (trailing == null) return pressable;
    // trailing อยู่นอกพื้นที่กด : ปุ่มซ้อนข้างใน (เช่น เมนู ⋮) ยังมี semantics/โฟกัสของตัวเอง และกดแล้วไม่ไปเรียก onTap ของแถว
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Row(children: [
        Expanded(child: pressable),
        Padding(padding: EdgeInsets.only(left: t.gap * 1.5, right: t.gap * 1.5), child: trailing!),
      ]),
    );
  }
}
