import { Router } from 'express';
import { NutritionController } from './nutritionController.js';
import { authGuard } from '../../middleware/authGuard.js';

export const nutritionRouter = Router();

nutritionRouter.use(authGuard);

// Catalog & Barcode
nutritionRouter.get('/foods/search', NutritionController.searchFoods);
nutritionRouter.get('/barcode/:barcode', NutritionController.getProductByBarcode);
nutritionRouter.post('/foods/custom', NutritionController.createCustomFood);

// Daily & Weekly Logs
nutritionRouter.get('/daily', NutritionController.getDailySummary);
nutritionRouter.post('/log', NutritionController.logMealItem);
nutritionRouter.put('/log/:itemId', NutritionController.updateMealItem);
nutritionRouter.delete('/log/:itemId', NutritionController.deleteMealItem);

// Water Log
nutritionRouter.post('/water', NutritionController.logWater);

// Weekly Summary
nutritionRouter.get('/summary/weekly', NutritionController.getWeeklySummary);
