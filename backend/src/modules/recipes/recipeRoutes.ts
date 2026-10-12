import { Router } from 'express';
import { RecipeController } from './recipeController.js';
import { authGuard } from '../../middleware/authGuard.js';

export const recipeRouter = Router();

// Public recipe browsing or auth-guarded
recipeRouter.use(authGuard);

// F09: Resep Sehat Indonesia
recipeRouter.get('/', RecipeController.getRecipes);
recipeRouter.get('/:id', RecipeController.getRecipeById);
recipeRouter.post('/:id/log-to-meal', RecipeController.logToMeal);
