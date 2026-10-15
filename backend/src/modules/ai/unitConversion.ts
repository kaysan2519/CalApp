// Indonesian Household Unit Normalization Table (docs/NUTRITION_RULES.md)

export interface UnitConversionRule {
  unitNames: string[];
  defaultGramWeight: number;
}

export const UNIT_CONVERSION_RULES: UnitConversionRule[] = [
  { unitNames: ['centong', 'centong nasi'], defaultGramWeight: 100 },
  { unitNames: ['piring', 'piring sedang'], defaultGramWeight: 200 },
  { unitNames: ['potong', 'potong sedang', 'iris'], defaultGramWeight: 50 },
  { unitNames: ['butir', 'butir telur', 'biji'], defaultGramWeight: 50 },
  { unitNames: ['sdm', 'sendok makan'], defaultGramWeight: 15 },
  { unitNames: ['sdt', 'sendok teh'], defaultGramWeight: 5 },
  { unitNames: ['mangkok', 'mangkuk'], defaultGramWeight: 250 },
  { unitNames: ['gelas', 'cangkir'], defaultGramWeight: 250 },
  { unitNames: ['bungkus', 'bks', 'pack'], defaultGramWeight: 85 },
  { unitNames: ['buah', 'biji'], defaultGramWeight: 100 },
  { unitNames: ['scoop'], defaultGramWeight: 30 },
  { unitNames: ['gram', 'g', 'gr'], defaultGramWeight: 1 },
  { unitNames: ['kg', 'kilogram'], defaultGramWeight: 1000 },
  { unitNames: ['ml', 'mili'], defaultGramWeight: 1 },
];

export function normalizeUnitToGrams(rawUnit: string, quantity: number): { normalizedGrams: number; standardUnit: string } {
  const cleanUnit = rawUnit.trim().toLowerCase();

  for (const rule of UNIT_CONVERSION_RULES) {
    if (rule.unitNames.some(u => cleanUnit.includes(u))) {
      return {
        normalizedGrams: Math.round(quantity * rule.defaultGramWeight),
        standardUnit: rule.unitNames[0],
      };
    }
  }

  throw {
    statusCode: 422,
    code: 'UNSUPPORTED_FOOD_UNIT',
    message: 'Satuan tersebut belum memiliki konversi gram yang terverifikasi. Sebutkan jumlah dalam gram atau satuan rumah tangga yang tersedia.',
  };
}
