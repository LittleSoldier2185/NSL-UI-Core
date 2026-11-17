import 'dart:ui';

import '../contrast/contrast.dart';
import '../format/theme_spec.dart';

/// ธีมในตัว: ต้องให้ค่าเท่าพาเลตต์เดิมของแต่ละแอปทุกตัว (ตรวจด้วย test/parity_*_test.dart ที่เทียบกับไฟล์ theme.dart จริง)
///
/// สีที่แอปเดิมไม่มี (เช่น `icon`, `hover`, `success*`) ปล่อยให้ derive
const kBuiltinDefaultId = 'nsl.default';
const kBuiltinDevId = 'nsl.nebular';
const kBuiltinResonanceId = 'nsl.spectrum';
const kBuiltinLyraPaperId = 'nsl.lyra.paper';

/// accent เริ่มต้นของ Resonance (Amber)
const kResonanceDefaultAccent = Color(0xFFF4B860);

/// NSL Dev: พาเลตต์ `kLightPalette` / `kDarkPalette` + ส่วนที่ `C` คำนวณตามโหมด
final NslThemeSpec kBuiltinDev = NslThemeSpec(
  id: kBuiltinDevId,
  name: 'NSL Nebular',
  light: const NslModeSpec(
    colors: {
      'bg': Color(0xFFEEF1F5),
      'chrome': Color(0xFFEEF1F5),
      'surface': Color(0xFFFFFFFF),
      'surfaceRaised': Color(0xFFFFFFFF),
      'surfaceSunken': Color(0xFFF3F5F8),
      'borderSoft': Color(0xFFE6EAF0),
      'border': Color(0xFFD8DEE6),
      'borderStrong': Color(0xFFCBD3DE),
      'text': Color(0xFF1B2430),
      'textMuted': Color(0xFF5B6778),
      'accent': Color(0xFF0F766E),
      'accentInk': Color(0xFF0B5A54),
      'accentTint': Color(0xFFE2F3F1),
      'onAccent': Color(0xFFFFFFFF),
      'danger': Color(0xFFB42318),
      'dangerBg': Color(0xFFFDE8E8),
      'dangerText': Color(0xFF7A1F1F),
      'warnBg': Color(0xFFFFF4D6),
      'warnText': Color(0xFF5C3D00),
      'infoBg': Color(0xFFE8EEF8),
      'infoText': Color(0xFF1E3A6B),
      'shadow': Color(0xFF0F172A),
    },
    extensions: {
      'nebular': {
        'canvas': Color(0xFFF6F8FB),
        'dot': Color(0xFFC3CCD8),
        'tableHead': Color(0xFF1F2A37),
        'pkBg': Color(0xFFFDEBD3),
        'pkText': Color(0xFF8A4B08),
        'uqBg': Color(0xFFEDE9FE),
        'uqText': Color(0xFF5B21B6),
        'nnBg': Color(0xFFE6EAF0),
        'nnText': Color(0xFF334155),
        'boardOutside': Color(0xFFE2E7EE),
        'boardEdge': Color(0xFFB4BFCD),
        'fkSource': Color(0xFFFFE9A8),
        'fkChip': Color(0xFFD9F0EC),
      },
    },
  ),
  dark: const NslModeSpec(
    colors: {
      'bg': Color(0xFF0E1319),
      'chrome': Color(0xFF0E1319),
      'surface': Color(0xFF19212B),
      'surfaceRaised': Color(0xFF212B37),
      'surfaceSunken': Color(0xFF222C38),
      'borderSoft': Color(0xFF242E3A),
      'border': Color(0xFF2E3946),
      'borderStrong': Color(0xFF3B4859),
      'text': Color(0xFFE6EBF2),
      'textMuted': Color(0xFF9AA7B8),
      'accent': Color(0xFF14958B),
      'accentInk': Color(0xFF5ED0C4),
      'accentTint': Color(0xFF133533),
      'onAccent': Color(0xFFFFFFFF),
      'danger': Color(0xFFF97066),
      'dangerBg': Color(0xFF3F1B1B),
      'dangerText': Color(0xFFFCA5A5),
      'warnBg': Color(0xFF3A2E10),
      'warnText': Color(0xFFF4D58A),
      'infoBg': Color(0xFF1B2A44),
      'infoText': Color(0xFF9DBBEA),
      'shadow': Color(0xFF000000),
    },
    extensions: {
      'nebular': {
        'canvas': Color(0xFF121820),
        'dot': Color(0xFF2A3544),
        'tableHead': Color(0xFF2A3848),
        'pkBg': Color(0xFF4A3213),
        'pkText': Color(0xFFF5B66B),
        'uqBg': Color(0xFF2E2552),
        'uqText': Color(0xFFC4B0FA),
        'nnBg': Color(0xFF2A3441),
        'nnText': Color(0xFFB5C0CE),
        'boardOutside': Color(0xFF0A0E13),
        'boardEdge': Color(0xFF3F4E62),
        'fkSource': Color(0xFF5A4A12),
        'fkChip': Color(0xFF16403D),
      },
    },
  ),
);

/// ธีมเริ่มต้นกลางของชุดโปรแกรม (ตอนนี้ใช้ค่าเดียวกับ NSL Dev — เปลี่ยนได้ภายหลังโดยไม่กระทบ `nsl.nebular`)
final NslThemeSpec kBuiltinDefault = NslThemeSpec(
  id: kBuiltinDefaultId,
  name: 'NSL Default',
  light: kBuiltinDev.light,
  dark: kBuiltinDev.dark,
);

/// NSL Resonance: เทียบเท่า `NslPalette.of(brightness, accent)` ทุกช่อง
///
/// `accentInk` คำนวณกับพื้น "14151A" (ธีมมืด) / ขาว (ธีมสว่าง) แบบเดียวกับของเดิม
NslThemeSpec builtinResonance([Color accent = kResonanceDefaultAccent]) {
  const surfaceLight = Color(0xFFFFFFFF);
  const surfaceDark = Color(0xFF14151A);
  return NslThemeSpec(
    id: kBuiltinResonanceId,
    name: 'NSL Spectrum',
    light: NslModeSpec(
      colors: {
        'bg': const Color(0xFFF1F2F6),
        'chrome': const Color(0xFFE7E9EF),
        'surface': const Color(0xFFFFFFFF),
        'surfaceRaised': const Color(0xFFFFFFFF),
        'surfaceSunken': const Color(0xFFE4E7EE),
        'borderSoft': const Color(0xFFE3E6EC),
        'borderStrong': const Color(0xFFC3C9D5),
        'text': const Color(0xFF14161C),
        'textMuted': const Color(0xFF5A6171),
        'icon': const Color(0xFF3A3F4E),
        'hover': const Color(0xFFE6E9F0),
        'accent': accent,
        'accentInk': inkFor(accent, surfaceLight, true),
        'onAccent': onAccentFor(accent),
      },
      extensions: const {
        'spectrum': {'panelBottom': Color(0xFFF5F6FA)},
      },
    ),
    dark: NslModeSpec(
      colors: {
        'bg': const Color(0xFF0C0D10),
        'chrome': const Color(0xFF0A0B0D),
        'surface': const Color(0xFF18191F),
        'surfaceRaised': const Color(0xFF18191F),
        'surfaceSunken': const Color(0xFF1B1D23),
        'borderSoft': const Color(0xFF272932),
        'borderStrong': const Color(0xFF2E313B),
        'text': const Color(0xFFECEDF1),
        'textMuted': const Color(0xFF9DA1AE),
        'icon': const Color(0xFFC9CCD6),
        'hover': const Color(0xFF1C1E24),
        'accent': accent,
        'accentInk': inkFor(accent, surfaceDark, false),
        'onAccent': onAccentFor(accent),
      },
      extensions: const {
        'spectrum': {'panelBottom': Color(0xFF121318)},
      },
    ),
  );
}


/// Lyra (NSL Writer Tools) "กระดาษอุ่น": พาเลตต์ `Palette.light` / `Palette.dark` ของแอป
///
/// การจับคู่: bg→bg · bgBar→chrome · bgPanel→surface · bgChip→surfaceSunken · line→border · lineSoft→borderSoft ·
/// lineInput→borderStrong · ink→text · inkSoft→textMuted · inkFaint→textFaint · inkSoft→icon · accentLine→accentBorder ·
/// saved→success · onAccent = bg (แอปใช้พื้นแอปเป็นสีตัวอักษรบนปุ่ม accent) ;
/// ที่เหลือ (body, accentDark, summary, snippet, chipText, border, dash, edge, navIndicator, ประเภท, สถานะ) อยู่ในส่วนขยาย `lyra`
/// สีสถานะอื่นที่แอปเดิมไม่มี (warn/info/dangerBg ฯลฯ) ปล่อยให้ derive
final NslThemeSpec kBuiltinLyraPaper = NslThemeSpec(
  id: kBuiltinLyraPaperId,
  name: 'Lyra Paper',
  light: const NslModeSpec(
    colors: {
      'bg': Color(0xFFFBF8F2),
      'chrome': Color(0xFFF4EFE6),
      'surface': Color(0xFFF7F3EB),
      'surfaceRaised': Color(0xFFF7F3EB),
      'surfaceSunken': Color(0xFFECE4D6),
      'borderSoft': Color(0xFFE3D9C8),
      'border': Color(0xFFD3C7B0),
      'borderStrong': Color(0xFFA89B84),
      'text': Color(0xFF1F1B16),
      'textMuted': Color(0xFF52493F),
      'textFaint': Color(0xFF6B6256),
      'icon': Color(0xFF52493F),
      'hover': Color(0xFFEAE0CE),
      'selected': Color(0xFFE2D6BF),
      'accent': Color(0xFFA8432A),
      'accentTint': Color(0xFFF6E4DC),
      'accentBorder': Color(0xFFD9A593),
      'onAccent': Color(0xFFFBF8F2),
      'danger': Color(0xFFB3261E),
      'success': Color(0xFF4F6D4F),
    },
    extensions: {
      'lyra': {
        'body': Color(0xFF2A241E),
        'accentDark': Color(0xFF8F3822),
        'summary': Color(0xFF3A332B),
        'snippet': Color(0xFF4F473E),
        'chipText': Color(0xFF3F382F),
        'border': Color(0xFFBBAE96),
        'dash': Color(0xFF8F8470),
        'edge': Color(0xFF8A7D66),
        'navIndicator': Color(0xFFE2D3BC),
        'typeCharacter': Color(0xFF9A4A2E),
        'typePlace': Color(0xFF3F6B4E),
        'typeOrg': Color(0xFF4A5A8A),
        'typeEvent': Color(0xFF8A6A2A),
        'typeItem': Color(0xFF6A4A7A),
        'typeRule': Color(0xFF2F6A6E),
        'typeSpecies': Color(0xFF7A5A3A),
        'statusIdeaBg': Color(0xFFEAE3D6),
        'statusIdeaFg': Color(0xFF4F463C),
        'statusDraftBg': Color(0xFFF3E4C3),
        'statusDraftFg': Color(0xFF6B4F12),
        'statusCanonBg': Color(0xFFD9E8D6),
        'statusCanonFg': Color(0xFF2C5A3C),
      },
    },
  ),
  dark: const NslModeSpec(
    colors: {
      'bg': Color(0xFF16130F),
      'chrome': Color(0xFF211C16),
      'surface': Color(0xFF1B1713),
      'surfaceRaised': Color(0xFF1B1713),
      'surfaceSunken': Color(0xFF342D23),
      'borderSoft': Color(0xFF3A3329),
      'border': Color(0xFF4F463A),
      'borderStrong': Color(0xFF76695A),
      'text': Color(0xFFF0E9DC),
      'textMuted': Color(0xFFCABFAB),
      'textFaint': Color(0xFFA89E8B),
      'icon': Color(0xFFCABFAB),
      'hover': Color(0xFF3A3228),
      'selected': Color(0xFF483B2D),
      'accent': Color(0xFFE08A68),
      'accentTint': Color(0xFF3A241B),
      'accentBorder': Color(0xFF8A5440),
      'onAccent': Color(0xFF16130F),
      'danger': Color(0xFFF2877D),
      'success': Color(0xFF9CC29C),
    },
    extensions: {
      'lyra': {
        'body': Color(0xFFDDD4C5),
        'accentDark': Color(0xFFC9714F),
        'summary': Color(0xFFD6CDBE),
        'snippet': Color(0xFFCFC5B3),
        'chipText': Color(0xFFE0D8C8),
        'border': Color(0xFF665A4A),
        'dash': Color(0xFF9A8F7C),
        'edge': Color(0xFF9C907A),
        'navIndicator': Color(0xFF483B2D),
        'typeCharacter': Color(0xFFDD8A66),
        'typePlace': Color(0xFF7FB68F),
        'typeOrg': Color(0xFF93A5DA),
        'typeEvent': Color(0xFFD7B463),
        'typeItem': Color(0xFFB994CE),
        'typeRule': Color(0xFF72B8BC),
        'typeSpecies': Color(0xFFC79D73),
        'statusIdeaBg': Color(0xFF2D2822),
        'statusIdeaFg': Color(0xFFB2A794),
        'statusDraftBg': Color(0xFF3A2F1B),
        'statusDraftFg': Color(0xFFD7B463),
        'statusCanonBg': Color(0xFF22352A),
        'statusCanonFg': Color(0xFF8FC8A0),
      },
    },
  ),
);

/// ธีมในตัวทั้งหมดตาม id (Resonance ใช้ accent เริ่มต้น)
NslThemeSpec? builtinThemeById(String id) => switch (id) {
      kBuiltinDefaultId => kBuiltinDefault,
      kBuiltinDevId => kBuiltinDev,
      kBuiltinResonanceId => builtinResonance(),
      kBuiltinLyraPaperId => kBuiltinLyraPaper,
      _ => null,
    };

const kBuiltinThemeIds = <String>[kBuiltinDefaultId, kBuiltinDevId, kBuiltinResonanceId, kBuiltinLyraPaperId];
