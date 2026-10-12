import { Router } from 'express';
import { AIController } from './aiController.js';
import { authGuard } from '../../middleware/authGuard.js';

export const aiRouter = Router();

aiRouter.use(authGuard);

// F02: Foto Makanan AI Vision
aiRouter.post('/food-vision', AIController.foodVision);

// F04: Teks Bahasa Sehari-hari
aiRouter.post('/food-text', AIController.foodText);

// F08: AI Nutrition Coach
aiRouter.post('/coach/chat', AIController.coachChat);

// F15: AI Workout Generator
aiRouter.post('/workout-generator', AIController.workoutGenerator);
