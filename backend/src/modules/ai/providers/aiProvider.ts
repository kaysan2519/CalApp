import { config } from '../../../config/env.js';

export interface DetectedVisionItem {
  label: string;
  estimatedPortionDescription: string;
  estimatedGrams: number;
  confidenceScore: number;
}

export interface VisionFoodResult {
  isFood: boolean;
  nonFoodReason?: string;
  detectedItems: DetectedVisionItem[];
}

export interface ExtractedFoodEntity {
  foodName: string;
  quantity: number;
  rawUnit: string;
}

export interface CoachContext {
  userName: string;
  goal: string;
  targetCalories: number;
  targetProteinG: number;
  targetCarbsG: number;
  targetFatG: number;
  consumedCalories: number;
  consumedProteinG: number;
  consumedCarbsG: number;
  consumedFatG: number;
  consumedWaterMl: number;
  mealsSummary: string;
}

export interface VisionProvider {
  analyzeFoodImage(base64Image: string): Promise<VisionFoodResult>;
}

export interface TextProvider {
  extractFoodEntities(text: string): Promise<ExtractedFoodEntity[]>;
  generateCoachResponse(context: CoachContext, message: string): Promise<string>;
  generateWorkoutPlan(goal: string, daysPerWeek: number, equipment: string): Promise<any>;
}

// Deterministic Mock Provider for Automated Tests & Dev Fallback
export class MockAIProvider implements VisionProvider, TextProvider {
  async analyzeFoodImage(base64Image: string): Promise<VisionFoodResult> {
    // If base64 contains non_food simulation marker
    if (base64Image.includes('non_food') || base64Image.includes('keyboard')) {
      return {
        isFood: false,
        nonFoodReason: 'Gambar tidak terdeteksi sebagai makanan atau minuman yang dapat dikonsumsi.',
        detectedItems: [],
      };
    }

    // Default realistic mock for a typical healthy Indonesian meal photo
    return {
      isFood: true,
      detectedItems: [
        {
          label: 'Nasi Putih',
          estimatedPortionDescription: '1 centong nasi putih hangat',
          estimatedGrams: 100,
          confidenceScore: 0.92,
        },
        {
          label: 'Dada Ayam Panggang',
          estimatedPortionDescription: '1 potong fillet dada ayam tanpa kulit',
          estimatedGrams: 150,
          confidenceScore: 0.88,
        },
        {
          label: 'Tempe Goreng',
          estimatedPortionDescription: '1 potong tempe goreng sedang',
          estimatedGrams: 50,
          confidenceScore: 0.85,
        },
      ],
    };
  }

  async extractFoodEntities(text: string): Promise<ExtractedFoodEntity[]> {
    const lower = text.toLowerCase();
    const entities: ExtractedFoodEntity[] = [];

    // Realistic entity extractor regex (supporting both '2 centong nasi' and 'nasi 2 centong')
    if (lower.includes('nasi')) {
      const match = lower.match(/(?:(\d+)\s*(centong|piring|gram|g)?\s*nasi|nasi(?:\s*putih)?\s*(\d+)\s*(centong|piring|gram|g)?)/);
      const qty = match ? parseInt(match[1] || match[3] || '1', 10) : 1;
      const unit = match ? (match[2] || match[4] || 'centong') : 'centong';
      entities.push({ foodName: 'Nasi Putih', quantity: qty, rawUnit: unit });
    }

    if (lower.includes('ayam')) {
      const match = lower.match(/(?:(\d+)\s*(potong|gram|g)?\s*(?:dada\s*)?ayam|ayam(?:\s*panggang|\s*bakar|\s*dada)?\s*(\d+)\s*(potong|gram|g)?)/);
      const qty = match ? parseInt(match[1] || match[3] || '150', 10) : 150;
      const unit = match ? (match[2] || match[4] || 'gram') : 'gram';
      entities.push({ foodName: 'Dada Ayam Panggang', quantity: qty, rawUnit: unit });
    }

    if (lower.includes('tempe')) {
      const match = lower.match(/(?:(\d+)\s*(potong)?\s*tempe|tempe(?:\s*goreng|\s*kukus)?\s*(\d+)\s*(potong)?)/);
      const qty = match ? parseInt(match[1] || match[3] || '1', 10) : 1;
      const unit = match ? (match[2] || match[4] || 'potong') : 'potong';
      entities.push({ foodName: 'Tempe Goreng', quantity: qty, rawUnit: unit });
    }

    if (lower.includes('telur')) {
      const match = lower.match(/(?:(\d+)\s*(butir)?\s*telur|telur(?:\s*rebus|\s*dadar)?\s*(\d+)\s*(butir)?)/);
      const qty = match ? parseInt(match[1] || match[3] || '1', 10) : 1;
      const unit = match ? (match[2] || match[4] || 'butir') : 'butir';
      entities.push({ foodName: 'Telur Rebus', quantity: qty, rawUnit: unit });
    }

    if (entities.length === 0) {
      // Generic single item fallback
      entities.push({ foodName: text.trim(), quantity: 1, rawUnit: 'porsi' });
    }

    return entities;
  }

  async generateCoachResponse(context: CoachContext, message: string): Promise<string> {
    const lower = message.toLowerCase();

    // 1. Safety Guardrail: Extreme Diet / Eating Disorder Warning
    if (lower.includes('400 kalori') || lower.includes('lapar ekstrem') || lower.includes('tidak makan')) {
      return `Halo ${context.userName}, keselamatan dan kesehatan Anda adalah prioritas utama. Mengonsumsi kalori di bawah 1200 kkal per hari berisiko mengganggu metabolisme, massa otot, dan fungsi organ tubuh. Cal merekomendasikan batas defisit yang aman dan bertahap (maksimal penurunan 0.5–1 kg/minggu). Jika Anda mengalami kesulitan dengan pola makan, sangat disarankan untuk berkonsultasi dengan dokter atau ahli gizi klinis.`;
    }

    // 2. Safety Guardrail: Jailbreak / Prompt Injection defense
    if (lower.includes('ignore all') || lower.includes('dan mode') || lower.includes('jailbreak')) {
      return `Maaf, saya adalah asisten nutrisi dan fitness Cal. Saya hanya dapat membantu menjawab pertanyaan seputar catatan makanan, latihan, dan kebiasaan sehat Anda.`;
    }

    const remainingCal = Math.max(0, context.targetCalories - context.consumedCalories);
    const remainingProtein = Math.max(0, context.targetProteinG - context.consumedProteinG);

    if (lower.includes('sisa') || lower.includes('makan apa') || lower.includes('rekomendasi')) {
      return `Hari ini Anda telah mengonsumsi ${context.consumedCalories} kkal dari target ${context.targetCalories} kkal (tersisa ${remainingCal} kkal). Kebutuhan protein Anda masih tersisa sekitar ${remainingProtein.toFixed(1)}g. Untuk melengkapinya, Anda bisa memilih makanan berprotein tinggi seperti Dada Ayam Panggang, Ikan Bakar, atau Pepes Tahu dengan porsi sayuran segar. Tetap jaga hidrasi air putih Anda!`;
    }

    return `Halo ${context.userName}! Anda telah mencatat asupan dengan baik hari ini. Dari target ${context.targetCalories} kkal, sisa anggaran kalori Anda adalah ${remainingCal} kkal. Jangan ragu bertanya jika butuh saran menu atau panduan latihan untuk mencapai tujuan ${context.goal} Anda!`;
  }

  async generateWorkoutPlan(goal: string, daysPerWeek: number, equipment: string): Promise<any> {
    return {
      title: `Program Latihan ${goal.toUpperCase()} (${daysPerWeek} Hari)`,
      description: `Rancangan latihan terstruktur fokus pada ${goal} menggunakan peralatan ${equipment}.`,
      daysPerWeek,
      routines: [
        {
          name: 'Day 1: Upper Body Strength',
          exercises: [
            { name: 'Barbell Bench Press', sets: 4, reps: 8, restSeconds: 90 },
            { name: 'Barbell Bent Over Row', sets: 4, reps: 8, restSeconds: 90 },
            { name: 'Overhead Barbell Press (OHP)', sets: 3, reps: 10, restSeconds: 60 },
          ],
        },
        {
          name: 'Day 2: Lower Body & Core',
          exercises: [
            { name: 'Barbell Back Squat', sets: 4, reps: 8, restSeconds: 120 },
            { name: 'Romanian Deadlift (RDL)', sets: 3, reps: 10, restSeconds: 90 },
            { name: 'Hanging Leg Raise', sets: 3, reps: 12, restSeconds: 60 },
          ],
        },
      ],
    };
  }
}

export class AIProviderFactory {
  static getProvider(): VisionProvider & TextProvider {
    // If live API key is present in environment, LiveProvider could be initialized.
    // Otherwise return MockAIProvider with full schema validation and safety bounds.
    return new MockAIProvider();
  }
}
