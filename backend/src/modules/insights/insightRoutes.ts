import { Router } from 'express';
import { authGuard } from '../../middleware/authGuard.js';
import { insightController } from './insightController.js';

const router = Router();

router.use(authGuard);

router.get('/weekly', (req, res) => insightController.getWeeklyInsights(req, res));

export default router;
