import 'package:flutter/material.dart';

import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';
import 'nsl_close_button.dart';

/// โทนของ alert
enum NslAlertTone { info, success, warn, danger }

/// กล่องแจ้งเตือนในหน้า (ไม่ลอย — ลอยใช้ toast) : ไอคอน + [title] + [message] + [action] + ปุ่มปิด
///
/// สีมาจากคู่ `*Bg/*Text` ที่ core รับประกัน contrast ≥ 4.5 ; สถานะไม่สื่อด้วยสีอย่างเดียว (มีไอคอนตามโทนเสมอ แก้ด้วย [icon])
/// - [onClose] ระบุ = แสดงปุ่มปิด ([closeTooltip] จำเป็นเมื่อมีปุ่มปิด)
/// - [announce] true (ค่าเริ่มต้น) = โปรแกรมอ่านหน้าจอประกาศเมื่อกล่องปรากฏ/เปลี่ยน
class NslAlert extends StatelessWidget {
  const NslAlert({
    super.key,
    required this.message,
    this.title,
    this.tone = NslAlertTone.info,
    this.icon,
    this.action,
    this.onClose,
    this.closeTooltip,
    this.announce = true,
  }) : assert(onClose == null || closeTooltip != null, 'closeTooltip จำเป็นเมื่อมี onClose');

  final String message;
  final String? title;
  final NslAlertTone tone;
  final IconData? icon;

  /// ปุ่ม/ลิงก์ใต้ข้อความ (เช่น `NslButton(kind: link)`)
  final Widget? action;
  final VoidCallback? onClose;
  final String? closeTooltip;
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final (bg, fg, defaultIcon) = switch (tone) {
      NslAlertTone.info => (c.infoBg, c.infoText, Icons.info_outline),
      NslAlertTone.success => (c.successBg, c.successText, Icons.check_circle_outline),
      NslAlertTone.warn => (c.warnBg, c.warnText, Icons.warning_amber_rounded),
      NslAlertTone.danger => (c.dangerBg, c.dangerText, Icons.error_outline),
    };
    final label = title == null ? message : '$title. $message';
    return Semantics(
      container: true,
      liveRegion: announce,
      explicitChildNodes: true,
      label: label,
      // เนื้อหาในกล่อง (ปุ่ม action/ปุ่มปิด) ต้องยังเข้าถึงได้ จึงไม่ตัด semantics ลูก — แต่ซ่อนข้อความซ้ำที่รวมใน label แล้ว
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: t.gap * 1.5, vertical: t.gap * 1.25),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(t.shape.md),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(top: t.gap / 4),
            child: ExcludeSemantics(child: Icon(icon ?? defaultIcon, size: t.type.fit(20), color: fg)),
          ),
          SizedBox(width: t.gap * 1.25),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              ExcludeSemantics(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  if (title != null) Text(title!, style: t.textStyle(15, weight: FontWeight.w600, color: fg)),
                  Text(message, style: t.textStyle(14, color: fg)),
                ]),
              ),
              if (action != null) Padding(padding: EdgeInsets.only(top: t.gap), child: action),
            ]),
          ),
          if (onClose != null) ...[
            SizedBox(width: t.gap),
            NslCloseButton(onPressed: onClose, tooltip: closeTooltip!, color: fg),
          ],
        ]),
      ),
    );
  }
}
