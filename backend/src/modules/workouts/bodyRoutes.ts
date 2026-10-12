import { Router } from 'express';
import { BodyController } from './bodyController.js';
import { authGuard } from '../../middleware/authGuard.js';

export const bodyRouter = Router();

bodyRouter.use(authGuard);

// F12: Progres Tubuh & Ukuran
bodyRouter.get('/measurements', BodyController.getMeasurements);
bodyRouter.post('/measurements', BodyController.logMeasurement);
