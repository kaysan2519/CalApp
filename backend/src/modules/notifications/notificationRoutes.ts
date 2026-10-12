import { Router } from 'express';
import { authGuard } from '../../middleware/authGuard.js';
import { notificationController } from './notificationController.js';

const router = Router();

router.use(authGuard);

router.get('/preferences', (req, res) => notificationController.getPreferences(req, res));
router.put('/preferences', (req, res) => notificationController.updatePreferences(req, res));

export default router;
