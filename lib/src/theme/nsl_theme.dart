import 'package:flutter/material.dart';

import '../builtin/builtin_themes.dart';
import '../format/resolve.dart';
import '../tokens/nsl_tokens.dart';

/// ทางที่ component ของ nsl_ui อ่าน token : แนบเป็น [ThemeExtension] ใน `ThemeData.extensions`
///
/// แอปที่ยังไม่ได้แนบ ก็ใช้ component ได้ — [NslContext.nsl] จะถอยไปใช้ token ของธีมในตัว
/// ตามโหมดสว่าง/มืดของ `Theme.of(context)` (ไม่พัง ไม่ต้องตั้งค่าก่อน)
class NslTheme extends ThemeExtension<NslTheme> {
  const NslTheme(this.tokens);

  final NslTokens tokens;

  @override
  NslTheme copyWith({NslTokens? tokens}) => NslTheme(tokens ?? this.tokens);

  /// token ไม่ใช่ตัวเลขต่อเนื่อง จึงสลับที่ครึ่งทาง (ไม่ผสมสี)
  @override
  NslTheme lerp(ThemeExtension<NslTheme>? other, double t) => other is NslTheme && t >= 0.5 ? other : this;

  @override
  bool operator ==(Object other) => other is NslTheme && tokens == other.tokens;

  @override
  int get hashCode => tokens.hashCode;
}

/// ใส่ token ให้ลูกทั้งต้นไม้โดยไม่แตะธีมที่เหลือ — ใช้พรีวิวคนละธีมกับแอป (เช่น Theme Editor)
///
/// ซ้อนทับ `Theme.of(context)` ปัจจุบัน : เพิ่มเฉพาะ [NslTheme] ส่วนสีของ Material
/// ยังเป็นของแอป (ถ้าต้องการให้ Material ตามด้วย ให้แอปสร้าง ThemeData จาก token เอง)
class NslThemeScope extends StatelessWidget {
  const NslThemeScope({super.key, required this.tokens, required this.child});

  final NslTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(extensions: [...base.extensions.values.where((e) => e is! NslTheme), NslTheme(tokens)]),
      child: child,
    );
  }
}

// token สำรองตามโหมด — resolve ครั้งเดียวตอนใช้ครั้งแรก (ธีมในตัวคงที่)
final NslTokens _fallbackLight = resolveTokens(kBuiltinDefault, Brightness.light);
final NslTokens _fallbackDark = resolveTokens(kBuiltinDefault, Brightness.dark);

/// token ที่ใช้เมื่อไม่มี [NslTheme] ในต้นไม้ (ธีม `nsl.default` ตามโหมด)
NslTokens nslFallbackTokens(Brightness b) => b == Brightness.dark ? _fallbackDark : _fallbackLight;

extension NslContext on BuildContext {
  /// token ของ NSL ที่ใช้อยู่ ณ จุดนี้ (อ่านจาก [NslTheme] ; ไม่มี = ธีมในตัวตามโหมดของ Theme)
  NslTokens get nsl {
    final t = Theme.of(this);
    return t.extension<NslTheme>()?.tokens ?? nslFallbackTokens(t.brightness);
  }

  /// แพลตฟอร์มจอสัมผัส (Android/iOS/Fuchsia) — component ใช้เพื่อไม่ให้พื้นที่แตะเล็กกว่า 44
  bool get nslTouch => switch (Theme.of(this).platform) {
        TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.fuchsia => true,
        _ => false,
      };
}
