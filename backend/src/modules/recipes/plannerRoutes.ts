import { Router } from 'express';
import { PlannerController } from './plannerController.js';
import { authGuard } from '../../middleware/authGuard.js';

export const plannerRouter = Router();

plannerRouter.use(authGuard);

// F10: Menu Harian AI
plannerRouter.post('/daily-generator', PlannerController.generateMenu);

// F11: Rencana Harian Terpadu
plannerRouter.get('/daily', PlannerController.getDailyPlan);
plannerRouter.post('/daily', PlannerController.saveDailyPlan);
