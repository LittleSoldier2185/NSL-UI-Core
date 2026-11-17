import 'package:flutter/material.dart';

import '../tokens/style_tokens.dart';
import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';

/// ระดับของแผง
enum NslPanelTone {
  /// พื้นปกติ (`surface`)
  surface,

  /// ลอยขึ้นจากพื้น (`surfaceRaised`) — มีเงาเมื่อธีมเปิดเงา
  raised,

  /// ยุบลง (`surfaceSunken`) — ใช้เป็นพื้นของช่อง/รายการย่อย
  sunken,
}

/// แผง/การ์ด : พื้น ขอบ มุมโค้ง และเงาจาก token (เงาตามโหมด `elevation` ของธีม — flat = ใช้ขอบอย่างเดียว)
///
/// [onTap] ไม่ null = ทั้งแผงกดได้ (มี Semantics ปุ่ม [semanticLabel])
class NslPanel extends StatelessWidget {
  const NslPanel({
    super.key,
    required this.child,
    this.tone = NslPanelTone.surface,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final NslPanelTone tone;

  /// ไม่ระบุ = ระยะตาม density
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.nsl, c = t.colors;
    final bg = switch (tone) {
      NslPanelTone.surface => c.surface,
      NslPanelTone.raised => c.surfaceRaised,
      NslPanelTone.sunken => c.surfaceSunken,
    };
    final radius = BorderRadius.circular(t.shape.lg);
    final shadows = tone == NslPanelTone.raised && t.elevation.mode == NslElevationMode.shadow && t.elevation.strength > 0
        ? [
            BoxShadow(
              color: c.shadow.withValues(alpha: (c.shadow.a * t.elevation.strength).clamp(0.0, 1.0)),
              blurRadius: t.gap * 2,
              offset: Offset(0, t.gap / 2),
            ),
          ]
        : null;

    final inner = Padding(padding: padding ?? EdgeInsets.all(t.gap * 2), child: child);
    // พื้น/ขอบ/เงาอยู่ที่ Container ชั้นนอก ; InkWell อยู่บน Material โปร่งข้างใน เพื่อให้เห็น hover/focus เหนือพื้น
    final body = Container(
      decoration: BoxDecoration(color: bg, borderRadius: radius, border: Border.all(color: c.borderSoft), boxShadow: shadows),
      child: onTap == null
          ? inner
          : Material(
              color: Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onTap, hoverColor: c.hover, focusColor: c.hover, child: inner),
            ),
    );
    if (onTap == null) return body;
    return Semantics(button: true, label: semanticLabel, child: body);
  }
}
