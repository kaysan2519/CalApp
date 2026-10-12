// Seed data for Cal App

export interface SeedFood {
  name: string;
  name_id: string;
  brand?: string;
  barcode?: string;
  serving_size: number;
  serving_unit: string;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  fiber_g: number;
  source: string;
  license: string;
  is_verified: boolean;
}

export const SEED_FOODS: SeedFood[] = [
  { name: 'White Rice (Cooked)', name_id: 'Nasi Putih', serving_size: 100, serving_unit: 'gram', calories: 130, protein_g: 2.7, carbs_g: 28.2, fat_g: 0.3, fiber_g: 0.4, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Brown Rice (Cooked)', name_id: 'Nasi Merah', serving_size: 100, serving_unit: 'gram', calories: 111, protein_g: 2.6, carbs_g: 23.0, fat_g: 0.9, fiber_g: 1.8, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Chicken Breast (Grilled/Cooked)', name_id: 'Dada Ayam Panggang', serving_size: 100, serving_unit: 'gram', calories: 165, protein_g: 31.0, carbs_g: 0.0, fat_g: 3.6, fiber_g: 0.0, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Hard Boiled Egg', name_id: 'Telur Rebus', serving_size: 50, serving_unit: 'butir', calories: 78, protein_g: 6.3, carbs_g: 0.6, fat_g: 5.3, fiber_g: 0.0, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Fried Tempeh', name_id: 'Tempe Goreng', serving_size: 50, serving_unit: 'potong', calories: 118, protein_g: 7.5, carbs_g: 4.8, fat_g: 8.2, fiber_g: 1.4, source: 'tkpi', license: 'Open Nutrition Data', is_verified: true },
  { name: 'Steamed Tempeh', name_id: 'Tempe Kukus', serving_size: 50, serving_unit: 'potong', calories: 85, protein_g: 9.5, carbs_g: 3.8, fat_g: 4.0, fiber_g: 1.8, source: 'tkpi', license: 'Open Nutrition Data', is_verified: true },
  { name: 'Fried Tofu', name_id: 'Tahu Goreng', serving_size: 50, serving_unit: 'potong', calories: 75, protein_g: 5.0, carbs_g: 2.5, fat_g: 5.2, fiber_g: 0.6, source: 'tkpi', license: 'Open Nutrition Data', is_verified: true },
  { name: 'White Tofu (Steamed)', name_id: 'Tahu Putih Kukus', serving_size: 100, serving_unit: 'gram', calories: 76, protein_g: 8.1, carbs_g: 1.9, fat_g: 4.8, fiber_g: 0.3, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Ayam Geprek (Without Skin/Oil)', name_id: 'Ayam Geprek Dada', serving_size: 150, serving_unit: 'porsi', calories: 240, protein_g: 32.0, carbs_g: 6.0, fat_g: 9.0, fiber_g: 1.0, source: 'custom_estimate', license: 'Cal Verified Recipe', is_verified: true },
  { name: 'Indonesian Omelette', name_id: 'Telur Dadar', serving_size: 60, serving_unit: 'butir', calories: 130, protein_g: 7.0, carbs_g: 1.2, fat_g: 11.0, fiber_g: 0.1, source: 'tkpi', license: 'Open Nutrition Data', is_verified: true },
  { name: 'Sayur Sop (Clear Vegetable Soup)', name_id: 'Sayur Sop', serving_size: 200, serving_unit: 'mangkok', calories: 65, protein_g: 2.5, carbs_g: 11.0, fat_g: 1.2, fiber_g: 2.5, source: 'tkpi', license: 'Open Nutrition Data', is_verified: true },
  { name: 'Soto Ayam (Clear Broth)', name_id: 'Soto Ayam', serving_size: 250, serving_unit: 'mangkok', calories: 180, protein_g: 18.0, carbs_g: 9.0, fat_g: 7.5, fiber_g: 1.5, source: 'tkpi', license: 'Open Nutrition Data', is_verified: true },
  { name: 'Gado-gado (With Peanut Sauce)', name_id: 'Gado-gado', serving_size: 250, serving_unit: 'porsi', calories: 310, protein_g: 14.0, carbs_g: 28.0, fat_g: 16.0, fiber_g: 5.5, source: 'tkpi', license: 'Open Nutrition Data', is_verified: true },
  { name: 'Tumis Kangkung (Stir-fried Water Spinach)', name_id: 'Tumis Kangkung', serving_size: 100, serving_unit: 'porsi', calories: 75, protein_g: 3.0, carbs_g: 4.5, fat_g: 5.0, fiber_g: 2.1, source: 'tkpi', license: 'Open Nutrition Data', is_verified: true },
  { name: 'Banana (Cavendish)', name_id: 'Pisang', serving_size: 100, serving_unit: 'buah', calories: 89, protein_g: 1.1, carbs_g: 22.8, fat_g: 0.3, fiber_g: 2.6, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Rolled Oats (Dry)', name_id: 'Oatmeal', serving_size: 40, serving_unit: 'gram', calories: 152, protein_g: 5.3, carbs_g: 27.0, fat_g: 2.6, fiber_g: 4.0, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Low Fat Cow Milk', name_id: 'Susu Rendah Lemak', serving_size: 200, serving_unit: 'ml', calories: 102, protein_g: 6.8, carbs_g: 10.2, fat_g: 4.0, fiber_g: 0.0, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Whey Protein Isolate', name_id: 'Whey Protein', serving_size: 30, serving_unit: 'scoop', calories: 120, protein_g: 25.0, carbs_g: 2.0, fat_g: 1.0, fiber_g: 0.0, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Olive Oil', name_id: 'Minyak Zaitun', serving_size: 14, serving_unit: 'sdm', calories: 119, protein_g: 0.0, carbs_g: 0.0, fat_g: 13.5, fiber_g: 0.0, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Peanut Butter (Natural)', name_id: 'Selai Kacang', serving_size: 32, serving_unit: 'sdm', calories: 188, protein_g: 8.0, carbs_g: 6.0, fat_g: 16.0, fiber_g: 2.0, source: 'usda', license: 'USDA FDC Public Domain', is_verified: true },
  { name: 'Indomie Goreng (Packaged Barcode Example)', name_id: 'Indomie Mi Instan Goreng', brand: 'Indofood', barcode: '089686010924', serving_size: 85, serving_unit: 'bungkus', calories: 380, protein_g: 8.0, carbs_g: 54.0, fat_g: 15.0, fiber_g: 3.0, source: 'open_food_facts', license: 'ODbL Open Food Facts', is_verified: true }
];

export const SEED_RECIPES = [
  {
    title: 'Ayam Panggang Bumbu Kuning Rendah Lemak',
    description: 'Dada ayam tanpa kulit dimarinasi kunyit, ketumbar, bawang putih, lalu dipanggang tanpa minyak.',
    prep_time_min: 15,
    cook_time_min: 25,
    servings: 2,
    calories_per_serving: 195,
    protein_per_serving: 34.0,
    carbs_per_serving: 4.5,
    fat_per_serving: 3.8,
    dietary_tags: ['Tinggi Protein', 'Rendah Lemak', 'Halal'],
    ingredients: [
      { name: 'Dada Ayam Fillet', qty: 250, unit: 'gram', calories: 300, protein: 56, carbs: 0, fat: 5 },
      { name: 'Bawang Putih & Kunyit Halus', qty: 30, unit: 'gram', calories: 30, protein: 1, carbs: 6, fat: 0 },
      { name: 'Air Jeruk Nipis', qty: 10, unit: 'ml', calories: 5, protein: 0, carbs: 1, fat: 0 }
    ],
    instructions: [
      'Bersihkan dada ayam fillet dan kerat permukaannya.',
      'Balurkan bumbu halus kunyit, bawang putih, garam secukupnya, dan jeruk nipis.',
      'Diamkan selama 15 menit agar meresap.',
      'Panggang di atas teflon anti lengket atau air fryer suhu 180°C selama 20–25 menit hingga matang sempurna.'
    ]
  },
  {
    title: 'Tumis Tempe Buncis Saus Tiram Sehat',
    description: 'Tempe kukus dipadu buncis renyah dengan sedikit saus tiram rendah garam.',
    prep_time_min: 10,
    cook_time_min: 12,
    servings: 2,
    calories_per_serving: 160,
    protein_per_serving: 12.0,
    carbs_per_serving: 14.0,
    fat_per_serving: 6.0,
    dietary_tags: ['Tinggi Serat', 'Vegetarian', 'Plant-Based'],
    ingredients: [
      { name: 'Tempe Potong Dadu', qty: 150, unit: 'gram', calories: 250, protein: 24, carbs: 11, fat: 12 },
      { name: 'Buncis Iris', qty: 100, unit: 'gram', calories: 35, protein: 2, carbs: 8, fat: 0 },
      { name: 'Saus Tiram Rendah Natrium', qty: 15, unit: 'ml', calories: 15, protein: 0, carbs: 3, fat: 0 }
    ],
    instructions: [
      'Kukus atau panggang tempe dadu sebentar tanpa minyak banyak.',
      'Tumis bawang merah, bawang putih, dan cabai dengan 1 sendok teh minyak.',
      'Masukkan buncis dan tempe, tambahkan saus tiram dan sedikit air.',
      'Masak hingga buncis matang namun tetap renyah.'
    ]
  },
  {
    title: 'Pepes Tahu Jamur Kemangi Wangi',
    description: 'Tahu putih halus dibumbui rempah dan jamur tiram, dibungkus daun pisang lalu dikukus.',
    prep_time_min: 15,
    cook_time_min: 20,
    servings: 2,
    calories_per_serving: 125,
    protein_per_serving: 9.5,
    carbs_per_serving: 7.0,
    fat_per_serving: 5.5,
    dietary_tags: ['Rendah Kalori', 'Vegetarian', 'Kaya Antioksidan'],
    ingredients: [
      { name: 'Tahu Putih', qty: 200, unit: 'gram', calories: 150, protein: 16, carbs: 4, fat: 9 },
      { name: 'Jamur Tiram Suwir', qty: 80, unit: 'gram', calories: 30, protein: 2, carbs: 5, fat: 0 },
      { name: 'Daun Kemangi & Bumbu Halus', qty: 40, unit: 'gram', calories: 20, protein: 1, carbs: 3, fat: 0 }
    ],
    instructions: [
      'Haluskan tahu putih, campur dengan jamur tiram, daun kemangi, dan bumbu halus.',
      'Bungkus dengan daun pisang dan semat dengan lidi.',
      'Kukus selama 20 menit hingga harum dan matang merata.'
    ]
  },
  {
    title: 'Sop Ikan Gurame Bening Kuah Jahe',
    description: 'Sup ikan berkuah bening segar dengan sensasi jahe dan tomat hijau.',
    prep_time_min: 15,
    cook_time_min: 20,
    servings: 2,
    calories_per_serving: 175,
    protein_per_serving: 28.0,
    carbs_per_serving: 4.0,
    fat_per_serving: 4.2,
    dietary_tags: ['Tinggi Protein', 'Rendah Lemak', 'Kaya Omega-3'],
    ingredients: [
      { name: 'Fillet Gurame / Kakap', qty: 250, unit: 'gram', calories: 240, protein: 48, carbs: 0, fat: 6 },
      { name: 'Tomat Hijau & Daun Bawang', qty: 80, unit: 'gram', calories: 25, protein: 1, carbs: 5, fat: 0 },
      { name: 'Jahe & Serai', qty: 30, unit: 'gram', calories: 15, protein: 0, carbs: 3, fat: 0 }
    ],
    instructions: [
      'Didihkan air kaldu dengan serai, jahe, dan daun jeruk.',
      'Masukkan fillet ikan, masak dengan api sedang agar daging tidak hancur.',
      'Tambahkan tomat hijau, perasan jeruk nipis, dan garam secukupnya menjelang matang.'
    ]
  },
  {
    title: 'Gado-gado Fit Dressing Kacang Mete',
    description: 'Sayuran rebus kaya serat dengan saus kacang mete panggang rendah minyak.',
    prep_time_min: 20,
    cook_time_min: 10,
    servings: 2,
    calories_per_serving: 220,
    protein_per_serving: 11.0,
    carbs_per_serving: 24.0,
    fat_per_serving: 9.0,
    dietary_tags: ['Tinggi Serat', 'Vegetarian', 'Bebas Kolesterol'],
    ingredients: [
      { name: 'Sayuran Rebus (Kangkung, Tauge, Kacang Panjang)', qty: 200, unit: 'gram', calories: 60, protein: 4, carbs: 12, fat: 0 },
      { name: 'Telur Rebus', qty: 50, unit: 'gram', calories: 78, protein: 6, carbs: 1, fat: 5 },
      { name: 'Dressing Kacang Mete Rendah Gula', qty: 40, unit: 'gram', calories: 160, protein: 6, carbs: 11, fat: 11 }
    ],
    instructions: [
      'Rebus sayuran sebentar agar nutrisi dan kerenyahan terjaga.',
      'Campur kacang mete panggang halus dengan asam jawa, cabai, dan air hangat.',
      'Tata sayuran, telur rebus potong, dan siram dengan kuah dressing.'
    ]
  },
  {
    title: 'Nasi Merah Bakar Ayam Jamur Suwir',
    description: 'Nasi merah beraroma bakaran daun pisang dengan isian dada ayam dan jamur gurih.',
    prep_time_min: 20,
    cook_time_min: 25,
    servings: 2,
    calories_per_serving: 290,
    protein_per_serving: 24.0,
    carbs_per_serving: 38.0,
    fat_per_serving: 4.8,
    dietary_tags: ['Karbohidrat Kompleks', 'Tinggi Protein', 'Halal'],
    ingredients: [
      { name: 'Nasi Merah Masak', qty: 200, unit: 'gram', calories: 220, protein: 5, carbs: 46, fat: 2 },
      { name: 'Dada Ayam Suwir', qty: 150, unit: 'gram', calories: 200, protein: 38, carbs: 0, fat: 4 },
      { name: 'Jamur Kancing & Daun Kemangi', qty: 80, unit: 'gram', calories: 35, protein: 2, carbs: 6, fat: 0 }
    ],
    instructions: [
      'Tumis ayam suwir dan jamur dengan bumbu rempah tanpa santan.',
      'Tata nasi merah di daun pisang, beri isian ayam jamur dan kemangi.',
      'Gulung rapi dan bakar di atas wajan pemanggang hingga daun layu kecokelatan.'
    ]
  },
  {
    title: 'Opor Dada Ayam Sehat Kuah FiberCreme',
    description: 'Kelezatan opor tradisional tanpa santan, memakai susu rendah lemak dan rempah lengkap.',
    prep_time_min: 15,
    cook_time_min: 30,
    servings: 3,
    calories_per_serving: 210,
    protein_per_serving: 30.0,
    carbs_per_serving: 6.0,
    fat_per_serving: 5.5,
    dietary_tags: ['Tinggi Protein', 'Rendah Lemak Jenuh', 'Halal'],
    ingredients: [
      { name: 'Dada Ayam Potong', qty: 350, unit: 'gram', calories: 420, protein: 80, carbs: 0, fat: 8 },
      { name: 'Susu Rendah Lemak / FiberCreme', qty: 200, unit: 'ml', calories: 120, protein: 6, carbs: 12, fat: 4 },
      { name: 'Bumbu Opor & Rempah Aromatik', qty: 40, unit: 'gram', calories: 40, protein: 1, carbs: 5, fat: 1 }
    ],
    instructions: [
      'Tumis bumbu halus bersama serai, daun salam, lengkuas dengan sedikit olive oil.',
      'Masukkan dada ayam, aduk hingga berubah warna.',
      'Tuangkan air dan susu rendah lemak, masak dengan api kecil hingga ayam empuk dan kuah meresap.'
    ]
  },
  {
    title: 'Sayur Asem Segar Jakarta Rendah Gula',
    description: 'Sup asam segar dengan kacang panjang, labu siam, dan jagung manis manis alami.',
    prep_time_min: 15,
    cook_time_min: 20,
    servings: 3,
    calories_per_serving: 85,
    protein_per_serving: 3.2,
    carbs_per_serving: 16.0,
    fat_per_serving: 1.1,
    dietary_tags: ['Rendah Kalori', 'Tinggi Serat', 'Bebas Lemak'],
    ingredients: [
      { name: 'Labu Siam & Kacang Panjang', qty: 200, unit: 'gram', calories: 60, protein: 3, carbs: 12, fat: 0 },
      { name: 'Jagung Manis Potong', qty: 100, unit: 'gram', calories: 86, protein: 3, carbs: 19, fat: 1 },
      { name: 'Asam Jawa & Bumbu Iris', qty: 30, unit: 'gram', calories: 25, protein: 1, carbs: 5, fat: 0 }
    ],
    instructions: [
      'Didihkan air kaldu dengan asam jawa dan bumbu rempah aromatik.',
      'Masukkan jagung manis, rebus hingga setengah matang.',
      'Tambahkan labu siam dan kacang panjang, masak hingga sayuran matang segar.'
    ]
  },
  {
    title: 'Sate Lilit Ayam Khas Bali Panggang',
    description: 'Sate ayam cincang berpadu serai dan kelapa parut sangrai tanpa minyak goreng.',
    prep_time_min: 20,
    cook_time_min: 15,
    servings: 2,
    calories_per_serving: 185,
    protein_per_serving: 27.0,
    carbs_per_serving: 5.0,
    fat_per_serving: 5.8,
    dietary_tags: ['Tinggi Protein', 'Halal', 'Kaya Rempah'],
    ingredients: [
      { name: 'Daging Ayam Giling Dada', qty: 250, unit: 'gram', calories: 280, protein: 50, carbs: 0, fat: 6 },
      { name: 'Kelapa Parut Muda Sangrai', qty: 25, unit: 'gram', calories: 60, protein: 1, carbs: 2, fat: 5 },
      { name: 'Batang Serai (Tusuk)', qty: 6, unit: 'batang', calories: 10, protein: 0, carbs: 2, fat: 0 }
    ],
    instructions: [
      'Campur ayam giling, bumbu genep halus, dan kelapa sangrai hingga liat.',
      'Lilitkan adonan ke batang serai.',
      'Panggang di atas grill pan anti lengket hingga berwarna keemasan dan matang.'
    ]
  },
  {
    title: 'Rawon Daging Sapi Tanpa Lemak Kuah Kluwek',
    description: 'Daging sapi has dalam kaya zat besi dengan kuah hitam kluwek khas Jawa Timur.',
    prep_time_min: 20,
    cook_time_min: 40,
    servings: 3,
    calories_per_serving: 230,
    protein_per_serving: 32.0,
    carbs_per_serving: 6.0,
    fat_per_serving: 7.2,
    dietary_tags: ['Tinggi Protein', 'Kaya Zat Besi', 'Halal'],
    ingredients: [
      { name: 'Daging Sapi Has Dalam (Tenderloin)', qty: 300, unit: 'gram', calories: 430, protein: 78, carbs: 0, fat: 12 },
      { name: 'Kluwek Matang & Bumbu Rawon', qty: 50, unit: 'gram', calories: 65, protein: 2, carbs: 9, fat: 2 },
      { name: 'Tauge Pendek Segar', qty: 50, unit: 'gram', calories: 15, protein: 1, carbs: 2, fat: 0 }
    ],
    instructions: [
      'Rebus daging sapi has dalam potong hingga empuk.',
      'Tumis bumbu halus kluwek dengan 1 sdt minyak hingga harum, lalu masukkan ke rebusan daging.',
      'Beri daun bawang dan sajikan hangat bersama tauge pendek segar.'
    ]
  },
  {
    title: 'Urap Sayur Bumbu Kelapa Sangrai Rendah Kalori',
    description: 'Kombinasi bayam, tauge, kacang panjang dengan sambal kelapa sangrai harum jeruk purut.',
    prep_time_min: 15,
    cook_time_min: 10,
    servings: 2,
    calories_per_serving: 110,
    protein_per_serving: 4.8,
    carbs_per_serving: 12.0,
    fat_per_serving: 4.5,
    dietary_tags: ['Vegetarian', 'Tinggi Serat', 'Tradisional'],
    ingredients: [
      { name: 'Bayam & Tauge Rebus', qty: 200, unit: 'gram', calories: 50, protein: 5, carbs: 8, fat: 0 },
      { name: 'Kelapa Parut Kukus Bumbu Urap', qty: 40, unit: 'gram', calories: 120, protein: 2, carbs: 6, fat: 8 }
    ],
    instructions: [
      'Kukus sayuran terpisah selama 3-5 menit agar tetap segar.',
      'Campur kelapa parut dengan bumbu halus kencur dan daun jeruk purut, lalu kukus sebentar.',
      'Campur sayuran dengan bumbu urap saat akan disantap.'
    ]
  },
  {
    title: 'Smoothie Bowl Buah Naga & Pisang Protein',
    description: 'Sarapan bernutrisi tinggi dengan buah naga segar, pisang, dan whey protein isolat.',
    prep_time_min: 10,
    cook_time_min: 0,
    servings: 1,
    calories_per_serving: 280,
    protein_per_serving: 26.0,
    carbs_per_serving: 40.0,
    fat_per_serving: 2.2,
    dietary_tags: ['Sarapan Cepat', 'Tinggi Protein', 'Tanpa Masak'],
    ingredients: [
      { name: 'Buah Naga Merah Beku', qty: 150, unit: 'gram', calories: 75, protein: 2, carbs: 16, fat: 1 },
      { name: 'Pisang Dingin', qty: 80, unit: 'gram', calories: 70, protein: 1, carbs: 18, fat: 0 },
      { name: 'Whey Protein Vanila', qty: 30, unit: 'gram', calories: 120, protein: 24, carbs: 2, fat: 1 }
    ],
    instructions: [
      'Masukkan buah naga beku, pisang, dan whey protein ke blender.',
      'Blender hingga kental dan lembut menyerupai soft-serve ice cream.',
      'Tuangkan ke mangkuk dan taburi sedikit chia seeds atau irisan pisang.'
    ]
  },
  {
    title: 'Telur Orak-Arik Bayam Tomat Tinggi Protein',
    description: 'Sarapan praktis 2 butir putih telur dan 1 butir utuh dengan bayam hijau dan tomat ceri.',
    prep_time_min: 5,
    cook_time_min: 7,
    servings: 1,
    calories_per_serving: 165,
    protein_per_serving: 18.0,
    carbs_per_serving: 4.5,
    fat_per_serving: 7.5,
    dietary_tags: ['Sarapan Cepat', 'Tinggi Protein', 'Keto-Friendly'],
    ingredients: [
      { name: 'Telur Ayam Utuh', qty: 1, unit: 'butir', calories: 78, protein: 6.3, carbs: 0.6, fat: 5.3 },
      { name: 'Putih Telur', qty: 2, unit: 'butir', calories: 34, protein: 7.2, carbs: 0.4, fat: 0.1 },
      { name: 'Bayam & Tomat Ceri', qty: 60, unit: 'gram', calories: 25, protein: 2, carbs: 4, fat: 0 }
    ],
    instructions: [
      'Kocok telur utuh dan putih telur dengan lada hitam dan sedikit garam.',
      'Tumis bayam dan tomat sebentar di atas wajan anti lengket.',
      'Tuangkan kocokan telur dan aduk perlahan (scramble) hingga matang lembut.'
    ]
  },
  {
    title: 'Ikan Bakar Bumbu Jimbaran Rendah Kalori',
    description: 'Ikan nila fillet panggang berlumur bumbu pedas manis dengan kecap rendah kalori.',
    prep_time_min: 15,
    cook_time_min: 20,
    servings: 2,
    calories_per_serving: 190,
    protein_per_serving: 32.0,
    carbs_per_serving: 5.0,
    fat_per_serving: 4.0,
    dietary_tags: ['Tinggi Protein', 'Halal', 'Rendah Lemak'],
    ingredients: [
      { name: 'Fillet Ikan Nila Segar', qty: 300, unit: 'gram', calories: 290, protein: 60, carbs: 0, fat: 5 },
      { name: 'Bumbu Jimbaran & Kecap Rendah Gula', qty: 40, unit: 'gram', calories: 45, protein: 1, carbs: 9, fat: 0 }
    ],
    instructions: [
      'Lumuri ikan dengan air jeruk nipis dan garam.',
      'Olesi bumbu halus Jimbaran tipis-tipis.',
      'Bakar di teflon atau grill pan hingga matang dan wangi berasap.'
    ]
  },
  {
    title: 'Overnight Oats Mangga Tropis Rendah Lemak',
    description: 'Oatmeal sarapan praktis disiapkan malam hari dengan susu almond dan potongan mangga harum manis.',
    prep_time_min: 10,
    cook_time_min: 0,
    servings: 1,
    calories_per_serving: 260,
    protein_per_serving: 9.0,
    carbs_per_serving: 46.0,
    fat_per_serving: 4.0,
    dietary_tags: ['Sarapan Praktis', 'Tinggi Serat', 'Vegan'],
    ingredients: [
      { name: 'Rolled Oats', qty: 40, unit: 'gram', calories: 152, protein: 5.3, carbs: 27, fat: 2.6 },
      { name: 'Susu Kedelai / Almond Tanpa Gula', qty: 150, unit: 'ml', calories: 45, protein: 3, carbs: 2, fat: 1.5 },
      { name: 'Mangga Harum Manis Iris', qty: 80, unit: 'gram', calories: 50, protein: 0.5, carbs: 13, fat: 0.2 }
    ],
    instructions: [
      'Campur rolled oats dan susu di dalam jar tertutup.',
      'Simpan di lemari es semalaman (minimal 4 jam).',
      'Tambahkan potongan mangga segar saat akan dinikmati di pagi hari.'
    ]
  },
  {
    title: 'Capcay Kuah Dada Ayam Sehat',
    description: 'Sayuran aneka warna (wortel, brokoli, kembang kol) dipadu dada ayam berkuah gurih alami.',
    prep_time_min: 15,
    cook_time_min: 15,
    servings: 2,
    calories_per_serving: 170,
    protein_per_serving: 22.0,
    carbs_per_serving: 12.0,
    fat_per_serving: 3.2,
    dietary_tags: ['Tinggi Serat', 'Tinggi Vitamin', 'Halal'],
    ingredients: [
      { name: 'Dada Ayam Iris', qty: 150, unit: 'gram', calories: 180, protein: 36, carbs: 0, fat: 3 },
      { name: 'Brokoli, Wortel, Kembang Kol', qty: 250, unit: 'gram', calories: 85, protein: 5, carbs: 17, fat: 0 },
      { name: 'Bawang Putih & Minyak Wijen (1 sdt)', qty: 15, unit: 'gram', calories: 45, protein: 0.5, carbs: 2, fat: 4 }
    ],
    instructions: [
      'Tumis bawang putih cincang dengan sedikit minyak wijen hingga harum.',
      'Masukkan dada ayam, aduk hingga memutih.',
      'Tambahkan air kaldu dan sayuran, masak hingga sayuran matang al dente.'
    ]
  },
  {
    title: 'Pecel Madiun Fit Saus Kacang Ringan',
    description: 'Bayam, tauge, dan keningkir dengan sambal pecel gurih beraroma kencur dan jeruk purut.',
    prep_time_min: 15,
    cook_time_min: 10,
    servings: 2,
    calories_per_serving: 195,
    protein_per_serving: 8.5,
    carbs_per_serving: 22.0,
    fat_per_serving: 8.2,
    dietary_tags: ['Tinggi Serat', 'Vegetarian', 'Tradisional'],
    ingredients: [
      { name: 'Sayuran Hijau Rebus (Bayam, Tauge, Kacang Panjang)', qty: 250, unit: 'gram', calories: 65, protein: 5, carbs: 12, fat: 0 },
      { name: 'Bumbu Pecel Rendah Gula', qty: 45, unit: 'gram', calories: 175, protein: 6, carbs: 16, fat: 10 }
    ],
    instructions: [
      'Rebus aneka sayuran sebentar, lalu tiriskan.',
      'Seduh bumbu pecel dengan sedikit air hangat hingga larut kekentalan pas.',
      'Siramkan di atas sayuran hijau segar.'
    ]
  },
  {
    title: 'Semur Tahu Tempe Kuah Rempah Hangat',
    description: 'Tahu dan tempe berkuah kecap rempah dengan pala dan kayu manis tanpa digoreng minyak banyak.',
    prep_time_min: 10,
    cook_time_min: 25,
    servings: 2,
    calories_per_serving: 180,
    protein_per_serving: 14.0,
    carbs_per_serving: 18.0,
    fat_per_serving: 6.0,
    dietary_tags: ['Vegetarian', 'Plant-Based Protein', 'Halal'],
    ingredients: [
      { name: 'Tahu Putih & Tempe', qty: 200, unit: 'gram', calories: 230, protein: 22, carbs: 10, fat: 10 },
      { name: 'Kecap Manis Rendah Gula & Rempah Semur', qty: 30, unit: 'ml', calories: 65, protein: 1, carbs: 15, fat: 0 }
    ],
    instructions: [
      'Potong tahu dan tempe sesuai selera, panggang sebentar di teflon kering.',
      'Tumis bumbu halus bawang merah, bawang putih, pala, dan merica.',
      'Masukkan air, kecap, tahu, dan tempe. Masak hingga kuah meresap.'
    ]
  },
  {
    title: 'Steak Tempe Panggang Saus Lada Hitam',
    description: 'Pilihan nabati berprotein tinggi: adonan tempe kukus dibentuk patty, dipanggang dengan saus lada hitam gurih.',
    prep_time_min: 20,
    cook_time_min: 15,
    servings: 2,
    calories_per_serving: 215,
    protein_per_serving: 16.0,
    carbs_per_serving: 21.0,
    fat_per_serving: 7.5,
    dietary_tags: ['Tinggi Protein', 'Vegetarian', 'Modern Sehat'],
    ingredients: [
      { name: 'Tempe Halus Kukus', qty: 200, unit: 'gram', calories: 280, protein: 26, carbs: 14, fat: 12 },
      { name: 'Putih Telur Pengikat', qty: 1, unit: 'butir', calories: 17, protein: 3.6, carbs: 0.2, fat: 0 },
      { name: 'Saus Lada Hitam Rendah Kalori', qty: 30, unit: 'ml', calories: 45, protein: 1, carbs: 9, fat: 0.5 }
    ],
    instructions: [
      'Campur tempe halus kukus dengan putih telur, bawang putih halus, garam, dan lada.',
      'Bentuk adonan menjadi 2 bulatan pipih patty.',
      'Panggang di teflon dengan sedikit semprotan olive oil hingga kedua sisi kecokelatan.',
      'Sajikan dengan siraman saus lada hitam hangat.'
    ]
  },
  {
    title: 'Soto Kudus Dada Ayam Kuah Bening',
    description: 'Soto berkuah bening khas Kudus disajikan dengan suwiran ayam gurih dan taburan bawang putih goreng.',
    prep_time_min: 15,
    cook_time_min: 30,
    servings: 2,
    calories_per_serving: 195,
    protein_per_serving: 29.0,
    carbs_per_serving: 8.0,
    fat_per_serving: 4.8,
    dietary_tags: ['Tinggi Protein', 'Rendah Lemak', 'Tradisional'],
    ingredients: [
      { name: 'Dada Ayam Rebus Suwir', qty: 220, unit: 'gram', calories: 260, protein: 52, carbs: 0, fat: 5 },
      { name: 'Tauge Segar & Seledri', qty: 60, unit: 'gram', calories: 20, protein: 1, carbs: 3, fat: 0 },
      { name: 'Kuah Kaldu Bumbu Rempah Kudus', qty: 400, unit: 'ml', calories: 50, protein: 2, carbs: 6, fat: 2 }
    ],
    instructions: [
      'Rebus dada ayam bersama serai, daun jeruk, dan bumbu kuning hingga harum.',
      'Angkat ayam lalu suwir-suwir.',
      'Tata tauge segar di mangkuk, beri ayam suwir, dan siramkan kuah kaldu soto panas.'
    ]
  }
];

export const SEED_EXERCISES = [
  // Chest
  { name: 'Barbell Bench Press', target_muscle: 'Chest', category: 'barbell', equipment: 'Barbell & Flat Bench' },
  { name: 'Incline Dumbbell Press', target_muscle: 'Chest', category: 'dumbbell', equipment: 'Dumbbells & Incline Bench' },
  { name: 'Dumbbell Flyes', target_muscle: 'Chest', category: 'dumbbell', equipment: 'Dumbbells & Flat Bench' },
  { name: 'Chest Dip', target_muscle: 'Chest', category: 'bodyweight', equipment: 'Dip Station' },
  { name: 'Cable Chest Fly', target_muscle: 'Chest', category: 'cable', equipment: 'Cable Machine' },
  { name: 'Push-Up', target_muscle: 'Chest', category: 'bodyweight', equipment: 'Bodyweight' },
  { name: 'Machine Chest Press', target_muscle: 'Chest', category: 'machine', equipment: 'Chest Press Machine' },
  { name: 'Decline Barbell Bench Press', target_muscle: 'Chest', category: 'barbell', equipment: 'Barbell & Decline Bench' },
  { name: 'Incline Barbell Bench Press', target_muscle: 'Chest', category: 'barbell', equipment: 'Barbell & Incline Bench' },
  { name: 'Pec Deck Fly', target_muscle: 'Chest', category: 'machine', equipment: 'Pec Deck Machine' },

  // Back
  { name: 'Conventional Deadlift', target_muscle: 'Back', category: 'barbell', equipment: 'Barbell' },
  { name: 'Barbell Bent Over Row', target_muscle: 'Back', category: 'barbell', equipment: 'Barbell' },
  { name: 'Pull-Up', target_muscle: 'Back', category: 'bodyweight', equipment: 'Pull-Up Bar' },
  { name: 'Chin-Up', target_muscle: 'Back', category: 'bodyweight', equipment: 'Pull-Up Bar' },
  { name: 'Lat Pulldown', target_muscle: 'Back', category: 'cable', equipment: 'Lat Pulldown Machine' },
  { name: 'Seated Cable Row', target_muscle: 'Back', category: 'cable', equipment: 'Cable Machine' },
  { name: 'Single-Arm Dumbbell Row', target_muscle: 'Back', category: 'dumbbell', equipment: 'Dumbbell & Bench' },
  { name: 'T-Bar Row', target_muscle: 'Back', category: 'barbell', equipment: 'T-Bar Platform' },
  { name: 'Chest-Supported Row', target_muscle: 'Back', category: 'machine', equipment: 'Machine / Incline Bench' },
  { name: 'Straight-Arm Cable Pulldown', target_muscle: 'Back', category: 'cable', equipment: 'Cable Machine' },
  { name: 'Hyperextensions (Back Extension)', target_muscle: 'Back', category: 'bodyweight', equipment: 'Back Extension Bench' },

  // Shoulders
  { name: 'Overhead Barbell Press (OHP)', target_muscle: 'Shoulders', category: 'barbell', equipment: 'Barbell' },
  { name: 'Seated Dumbbell Shoulder Press', target_muscle: 'Shoulders', category: 'dumbbell', equipment: 'Dumbbells & Bench' },
  { name: 'Dumbbell Lateral Raise', target_muscle: 'Shoulders', category: 'dumbbell', equipment: 'Dumbbells' },
  { name: 'Cable Lateral Raise', target_muscle: 'Shoulders', category: 'cable', equipment: 'Cable Machine' },
  { name: 'Rear Delt Reverse Fly', target_muscle: 'Shoulders', category: 'dumbbell', equipment: 'Dumbbells' },
  { name: 'Face Pull', target_muscle: 'Shoulders', category: 'cable', equipment: 'Cable Machine & Rope' },
  { name: 'Arnold Press', target_muscle: 'Shoulders', category: 'dumbbell', equipment: 'Dumbbells & Bench' },
  { name: 'Front Dumbbell Raise', target_muscle: 'Shoulders', category: 'dumbbell', equipment: 'Dumbbells' },
  { name: 'Barbell Upright Row', target_muscle: 'Shoulders', category: 'barbell', equipment: 'Barbell' },
  { name: 'Machine Shoulder Press', target_muscle: 'Shoulders', category: 'machine', equipment: 'Shoulder Press Machine' },

  // Quadriceps & Glutes (Legs)
  { name: 'Barbell Back Squat', target_muscle: 'Quads', category: 'barbell', equipment: 'Barbell & Squat Rack' },
  { name: 'Barbell Front Squat', target_muscle: 'Quads', category: 'barbell', equipment: 'Barbell & Squat Rack' },
  { name: 'Leg Press', target_muscle: 'Quads', category: 'machine', equipment: 'Leg Press Machine' },
  { name: 'Bulgarian Split Squat', target_muscle: 'Quads', category: 'dumbbell', equipment: 'Dumbbells & Bench' },
  { name: 'Walking Lunges', target_muscle: 'Quads', category: 'dumbbell', equipment: 'Dumbbells' },
  { name: 'Goblet Squat', target_muscle: 'Quads', category: 'dumbbell', equipment: 'Kettlebell / Dumbbell' },
  { name: 'Leg Extension', target_muscle: 'Quads', category: 'machine', equipment: 'Leg Extension Machine' },
  { name: 'Hack Squat', target_muscle: 'Quads', category: 'machine', equipment: 'Hack Squat Machine' },
  { name: 'Barbell Hip Thrust', target_muscle: 'Glutes', category: 'barbell', equipment: 'Barbell & Bench' },
  { name: 'Glute Cable Kickback', target_muscle: 'Glutes', category: 'cable', equipment: 'Cable Machine' },
  { name: 'Step-Ups', target_muscle: 'Quads', category: 'dumbbell', equipment: 'Box / Bench & Dumbbells' },

  // Hamstrings & Calves
  { name: 'Romanian Deadlift (RDL)', target_muscle: 'Hamstrings', category: 'barbell', equipment: 'Barbell' },
  { name: 'Dumbbell Romanian Deadlift', target_muscle: 'Hamstrings', category: 'dumbbell', equipment: 'Dumbbells' },
  { name: 'Lying Leg Curl', target_muscle: 'Hamstrings', category: 'machine', equipment: 'Leg Curl Machine' },
  { name: 'Seated Leg Curl', target_muscle: 'Hamstrings', category: 'machine', equipment: 'Seated Leg Curl Machine' },
  { name: 'Standing Calf Raise', target_muscle: 'Calves', category: 'machine', equipment: 'Calf Raise Machine' },
  { name: 'Seated Calf Raise', target_muscle: 'Calves', category: 'machine', equipment: 'Seated Calf Machine' },
  { name: 'Single-Leg Dumbbell Calf Raise', target_muscle: 'Calves', category: 'dumbbell', equipment: 'Dumbbell & Step' },

  // Biceps
  { name: 'Barbell Biceps Curl', target_muscle: 'Biceps', category: 'barbell', equipment: 'Barbell / EZ Bar' },
  { name: 'Dumbbell Incline Curl', target_muscle: 'Biceps', category: 'dumbbell', equipment: 'Dumbbells & Incline Bench' },
  { name: 'Hammer Curl', target_muscle: 'Biceps', category: 'dumbbell', equipment: 'Dumbbells' },
  { name: 'Preacher Curl', target_muscle: 'Biceps', category: 'barbell', equipment: 'EZ Bar & Preacher Bench' },
  { name: 'Cable Biceps Curl', target_muscle: 'Biceps', category: 'cable', equipment: 'Cable Machine' },
  { name: 'Concentration Curl', target_muscle: 'Biceps', category: 'dumbbell', equipment: 'Dumbbell & Bench' },
  { name: 'Spider Curl', target_muscle: 'Biceps', category: 'dumbbell', equipment: 'Dumbbells & Incline Bench' },

  // Triceps
  { name: 'Triceps Rope Pushdown', target_muscle: 'Triceps', category: 'cable', equipment: 'Cable Machine & Rope' },
  { name: 'Skull Crusher (Lying Triceps Extension)', target_muscle: 'Triceps', category: 'barbell', equipment: 'EZ Bar & Bench' },
  { name: 'Overhead Cable Triceps Extension', target_muscle: 'Triceps', category: 'cable', equipment: 'Cable Machine' },
  { name: 'Close-Grip Barbell Bench Press', target_muscle: 'Triceps', category: 'barbell', equipment: 'Barbell & Bench' },
  { name: 'Dumbbell Triceps Kickback', target_muscle: 'Triceps', category: 'dumbbell', equipment: 'Dumbbells' },
  { name: 'Parallel Bar Triceps Dip', target_muscle: 'Triceps', category: 'bodyweight', equipment: 'Dip Station' },
  { name: 'Bench Dip', target_muscle: 'Triceps', category: 'bodyweight', equipment: 'Bench' },

  // Core & Abs
  { name: 'Hanging Leg Raise', target_muscle: 'Abs', category: 'bodyweight', equipment: 'Pull-Up Bar' },
  { name: 'Cable Crunch', target_muscle: 'Abs', category: 'cable', equipment: 'Cable Machine & Rope' },
  { name: 'Plank', target_muscle: 'Abs', category: 'bodyweight', equipment: 'Yoga Mat' },
  { name: 'Ab Wheel Rollout', target_muscle: 'Abs', category: 'bodyweight', equipment: 'Ab Wheel' },
  { name: 'Russian Twist', target_muscle: 'Abs', category: 'bodyweight', equipment: 'Medicine Ball / Plate' },
  { name: 'Decline Sit-Up', target_muscle: 'Abs', category: 'bodyweight', equipment: 'Decline Bench' },
  { name: 'Side Plank', target_muscle: 'Abs', category: 'bodyweight', equipment: 'Yoga Mat' },
  { name: 'Mountain Climbers', target_muscle: 'Abs', category: 'bodyweight', equipment: 'Bodyweight' },

  // Cardio & Functional
  { name: 'Treadmill Running / Incline Walk', target_muscle: 'Cardio', category: 'cardio', equipment: 'Treadmill' },
  { name: 'Stationary Cycling', target_muscle: 'Cardio', category: 'cardio', equipment: 'Exercise Bike' },
  { name: 'Rowing Machine', target_muscle: 'Cardio', category: 'cardio', equipment: 'Rower' },
  { name: 'Kettlebell Swing', target_muscle: 'Full Body', category: 'dumbbell', equipment: 'Kettlebell' },
  { name: 'Burpees', target_muscle: 'Full Body', category: 'bodyweight', equipment: 'Bodyweight' },
  { name: 'Jump Rope', target_muscle: 'Cardio', category: 'cardio', equipment: 'Jump Rope' },
  { name: 'Farmers Walk', target_muscle: 'Full Body', category: 'dumbbell', equipment: 'Heavy Dumbbells / Trap Bar' },
  { name: 'Trap Bar Deadlift', target_muscle: 'Back & Quads', category: 'barbell', equipment: 'Trap Bar' },
  { name: 'Box Jump', target_muscle: 'Legs', category: 'bodyweight', equipment: 'Plyometric Box' },
  { name: 'Battle Ropes', target_muscle: 'Full Body', category: 'functional', equipment: 'Battle Ropes' }
];

export const SEED_ACHIEVEMENTS = [
  { code: 'FIRST_MEAL', title: 'Langkah Pertama', description: 'Mencatat makanan pertama di Cal', icon_name: 'restaurant', xp_reward: 50 },
  { code: 'HYDRATION_HERO', title: 'Ksatria Air', description: 'Mencapai target minum air 3 hari beruntun', icon_name: 'water_drop', xp_reward: 75 },
  { code: 'FIRST_WORKOUT', title: 'Pahlawan Angkat Beban', description: 'Menyelesaikan sesi latihan gym pertama', icon_name: 'fitness_center', xp_reward: 75 },
  { code: 'STREAK_7_DAYS', title: 'Streak Emas 7 Hari', description: 'Mencatat nutrisi atau latihan selama 7 hari berturut-turut', icon_name: 'local_fire_department', xp_reward: 150 },
  { code: 'FIRST_PR', title: 'Pencetak Rekor', description: 'Mencetak Personal Record (PR) pertama', icon_name: 'emoji_events', xp_reward: 100 },
  { code: 'COMMUNITY_JOIN', title: 'Sahabat Sehat', description: 'Bergabung dengan grup komunitas', icon_name: 'groups', xp_reward: 50 }
];

export const SEED_CHALLENGES = [
  {
    title: 'Konsistensi Nutrisi Hari Ini',
    description: 'Catat setidaknya 3 waktu makan (Sarapan, Makan Siang, Makan Malam)',
    challenge_type: 'daily',
    target_metric: 'meals_logged',
    target_value: 3,
    xp_reward: 35
  },
  {
    title: 'Target Hidrasi Harian',
    description: 'Minum minimal 2000 ml air hari ini',
    challenge_type: 'daily',
    target_metric: 'water_ml',
    target_value: 2000,
    xp_reward: 25
  },
  {
    title: '3x Gym Warrior Mingguan',
    description: 'Selesaikan minimal 3 sesi latihan beban dalam minggu ini',
    challenge_type: 'weekly',
    target_metric: 'workouts_completed',
    target_value: 3,
    xp_reward: 100
  }
];
