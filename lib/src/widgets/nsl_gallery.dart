import 'package:flutter/material.dart';

import '../components/nsl_badge.dart';
import '../components/nsl_button.dart';
import '../components/nsl_empty_state.dart';
import '../components/nsl_icon_button.dart';
import '../components/nsl_list_row.dart';
import '../components/nsl_nav_item.dart';
import '../components/nsl_panel.dart';
import '../components/nsl_progress_bar.dart';
import '../contrast/contrast.dart';
import '../theme/component_metrics.dart';
import '../theme/nsl_theme.dart';
import '../tokens/color_tokens.dart';
import '../tokens/nsl_tokens.dart';

/// หน้าตัวอย่าง widget มาตรฐานภายใต้ธีมปัจจุบัน — ใช้เป็นพรีวิวใน Theme Editor และเป็นเป้าของเทสต์
/// อ่านสีจาก [Theme.of] จึงสะท้อนสิ่งที่ผู้ใช้จะเห็นในแอปจริง (ไม่ใช่ mock)
class NslGallery extends StatelessWidget {
  const NslGallery({super.key, this.tokens});

  /// ถ้าระบุ จะแสดงตารางสี + contrast ของ token ด้วย
  final NslTokens? tokens;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('nsl-gallery'),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Heading', style: t.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Body text สำหรับตัวอย่างภาษาไทย 123', style: t.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(onPressed: () {}, child: const Text('Primary')),
          OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
          TextButton(onPressed: () {}, child: const Text('Text')),
          const FilledButton(onPressed: null, child: Text('Disabled')),
          const Chip(label: Text('Chip')),
          Switch(value: true, onChanged: (_) {}),
          Checkbox(value: true, onChanged: (_) {}),
        ]),
        const SizedBox(height: 12),
        const SizedBox(width: 280, child: TextField(decoration: InputDecoration(labelText: 'Text field', border: OutlineInputBorder()))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Card', style: t.textTheme.bodyMedium))),
        const SizedBox(height: 12),
        const LinearProgressIndicator(value: 0.6),
        const SizedBox(height: 16),
        Text('Components', style: t.textTheme.titleMedium),
        const SizedBox(height: 8),
        // ถ้าระบุ tokens ให้ component พรีวิวด้วยธีมนั้น (ไม่ใช่ธีมของแอปที่ถือ Gallery)
        if (tokens != null) NslThemeScope(tokens: tokens!, child: const _Components()) else const _Components(),
        if (tokens != null) ...[
          const SizedBox(height: 16),
          _ColorTable(tokens!),
        ],
      ]),
    );
  }
}

/// ชุด component กลางของ nsl_ui ทุกชนิด/สถานะ — ใช้ดูหน้าตาและเป็นเป้าของเทสต์ overflow
class _Components extends StatelessWidget {
  const _Components();

  @override
  Widget build(BuildContext context) {
    final gap = context.nsl.gap;
    void noop() {}
    return Column(key: const ValueKey('nsl-gallery-components'), crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: gap, runSpacing: gap, children: [
        // ป้ายขึ้นต้นด้วย "Nsl" เพื่อไม่ซ้ำกับข้อความเดิมของ Gallery ('Primary', 'accent' ฯลฯ ที่เทสต์เดิมจับอยู่)
        NslButton(label: 'Nsl primary', kind: NslButtonKind.primary, icon: Icons.check, onPressed: noop),
        NslButton(label: 'Nsl secondary', onPressed: noop),
        NslButton(label: 'Nsl danger', kind: NslButtonKind.danger, onPressed: noop),
        NslButton(label: 'Nsl ghost', kind: NslButtonKind.ghost, onPressed: noop),
        const NslButton(label: 'Nsl disabled', onPressed: null),
      ]),
      SizedBox(height: gap),
      Wrap(spacing: gap, runSpacing: gap, crossAxisAlignment: WrapCrossAlignment.center, children: [
        NslIconButton(icon: Icons.add, tooltip: 'Add', onPressed: noop),
        NslIconButton(icon: Icons.view_sidebar, tooltip: 'Toggle panel', selected: true, onPressed: noop),
        const NslIconButton(icon: Icons.delete, tooltip: 'Delete', onPressed: null),
        for (final tone in NslBadgeTone.values) NslBadge('Nsl ${tone.name}', tone: tone),
      ]),
      SizedBox(height: gap),
      const NslPanel(tone: NslPanelTone.raised, child: Text('Nsl panel (raised)')),
      SizedBox(height: gap),
      for (final tone in NslProgressTone.values) ...[
        SizedBox(width: 240, child: NslProgressBar(value: 0.6, label: 'Nsl progress ${tone.name}', tone: tone)),
        SizedBox(height: gap),
      ],
      NslPanel(
        child: Column(children: [
          NslListRow(title: 'Nsl list row', subtitle: 'subtitle', leading: const Icon(Icons.music_note), trailing: const Icon(Icons.more_vert), onTap: noop),
          NslListRow(title: 'Nsl list row selected', subtitle: 'selected', selected: true, onTap: noop),
          NslListRow(title: 'Nsl list row active', subtitle: 'active', active: true, onTap: noop),
        ]),
      ),
      SizedBox(height: gap),
      SizedBox(
        width: 220,
        child: Column(children: [
          NslNavItem(icon: Icons.home, label: 'Nsl nav selected', selected: true, badge: 3, onTap: noop),
          NslNavItem(icon: Icons.search, label: 'Nsl nav', selected: false, onTap: noop),
        ]),
      ),
      SizedBox(height: gap),
      Row(children: [
        NslNavItem(icon: Icons.home, label: 'Nsl nav collapsed', selected: true, collapsed: true, onTap: noop),
        SizedBox(width: gap),
        NslNavItem(icon: Icons.inbox, label: 'Nsl nav collapsed badge', selected: false, collapsed: true, badge: 9, onTap: noop),
      ]),
      SizedBox(height: gap),
      // ความสูงจำกัด : Gallery เองเลื่อนอยู่แล้ว และ NslEmptyState เลื่อนได้ในตัว (ห้ามซ้อนเลื่อนในพื้นที่สูงไม่จำกัด)
      NslPanel(
        tone: NslPanelTone.sunken,
        child: SizedBox(
          height: 180,
          child: NslEmptyState(
            icon: Icons.inbox,
            title: 'Nsl empty state',
            message: 'Nothing here yet',
            action: NslButton(label: 'Nsl create', kind: NslButtonKind.primary, onPressed: noop),
          ),
        ),
      ),
    ]);
  }
}

class _ColorTable extends StatelessWidget {
  const _ColorTable(this.tokens);
  final NslTokens tokens;

  @override
  Widget build(BuildContext context) {
    final c = tokens.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final k in kCoreColorKeys)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(color: c[k], border: Border.all(color: Colors.black26))),
            const SizedBox(width: 8),
            SizedBox(width: 120, child: Text(k)),
            Text(contrastRatio(c[k], c.surface).toStringAsFixed(2)),
          ]),
        ),
    ]);
  }
}
