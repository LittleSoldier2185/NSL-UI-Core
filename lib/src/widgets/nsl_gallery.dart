import 'package:flutter/material.dart';

import '../contrast/contrast.dart';
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
        if (tokens != null) ...[
          const SizedBox(height: 16),
          _ColorTable(tokens!),
        ],
      ]),
    );
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
