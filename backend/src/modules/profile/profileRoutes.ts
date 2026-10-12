import { Router } from 'express';
import { ProfileController } from './profileController.js';
import { authGuard } from '../../middleware/authGuard.js';

export const profileRouter = Router();

profileRouter.use(authGuard);

profileRouter.get('/', ProfileController.getProfile);
profileRouter.put('/', ProfileController.updateProfile);
profileRouter.get('/targets', ProfileController.getTargets);
profileRouter.put('/targets', ProfileController.updateManualTargets);
