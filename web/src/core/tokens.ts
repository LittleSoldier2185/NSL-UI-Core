import schemaJson from '../../../schema/tokens.schema.json';
import type { Color } from './color';

/** schema ที่ฝั่ง Dart สร้าง (buildTokensSchema) — แหล่งความจริงของรายชื่อ token, ช่วงค่า, preset */
export interface TokensSchema {
  schema: number;
  core: string;
  colors: { key: string; group: string; root: boolean; accentDependent: boolean; since: string }[];
  extensions: { name: string; app: string; keys: string[]; accentDependents: string[]; since: string }[];
  shape: { radius: { keys: string[]; default: Record<string, number>; min: number; max: number } };
  type: {
    roles: string[];
    scale: { min: number; max: number; default: number };
    minSize: { min: number; max: number };
    fontNameMaxLength: number;
  };
  density: string[];
  elevation: { modes: string[]; strength: { min: number; max: number; default: number } };
  appearance: {
    modes: string[];
    presets: { id: string; nameTh: string; nameEn: string; light: PresetSet; dark: PresetSet }[];
  };
  builtinThemes: { id: string; name: string }[];
  limits: { maxFileBytes: number; idPattern: string; reservedIdPrefix: string };
}
export interface PresetSet {
  accent: string;
  soft: string;
  ink: string;
}

export const schema = schemaJson as unknown as TokensSchema;

export type Brightness = 'light' | 'dark';
export type Colors = Record<string, Color>;

/** ชื่อ token สี core ทั้งหมด (ลำดับตาม schema) */
export const kCoreColorKeys: readonly string[] = schema.colors.map((c) => c.key);
/** สี root ที่ต้องระบุเสมอ (ที่เหลือ derive ได้) */
export const kRootColorKeys: readonly string[] = schema.colors.filter((c) => c.root).map((c) => c.key);
/** token ที่คำนวณจาก accent */
export const kAccentDependents: readonly string[] = schema.colors.filter((c) => c.accentDependent).map((c) => c.key);

export type Density = 'compact' | 'normal' | 'comfortable';
export type ElevationMode = 'shadow' | 'flat';

export interface NslShape {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  pill: number;
}
export interface NslType {
  family?: string;
  content?: string;
  mono?: string;
  scale: number;
  minSize?: number;
}

/** token ทั้งหมดของหนึ่งโหมดที่ resolve ครบแล้ว */
export interface NslTokens {
  brightness: Brightness;
  colors: Colors;
  shape: NslShape;
  type: NslType;
  density: Density;
  elevation: { mode: ElevationMode; strength: number };
  extensions: Record<string, Colors>;
}
