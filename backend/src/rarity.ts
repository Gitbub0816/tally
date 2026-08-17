export interface RarityFactors {
  readonly typeScarcity: number; readonly liveryScarcity: number; readonly operatorScarcity: number;
  readonly localScarcity: number; readonly eventSignificance: number; readonly firstPersonalSighting: boolean;
}
const clamp = (value: number): number => Math.max(0, Math.min(1, value));
export function rarity(factors: RarityFactors): { score: number; tier: string } {
  const weighted = clamp(factors.typeScarcity) * 0.14 + clamp(factors.liveryScarcity) * 0.25 +
    clamp(factors.operatorScarcity) * 0.12 + clamp(factors.localScarcity) * 0.31 +
    clamp(factors.eventSignificance) * 0.12 + (factors.firstPersonalSighting ? 0.06 : 0);
  const score = Math.max(0, Math.min(100, Math.round(weighted * 100)));
  const tier = score >= 92 ? "singular" : score >= 78 ? "exceptional" : score >= 60 ? "rare" : score >= 35 ? "notable" : "frequent";
  return { score, tier };
}
