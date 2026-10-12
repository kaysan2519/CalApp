import { Router } from 'express';
import { AuthController } from './authController.js';
import { authGuard } from '../../middleware/authGuard.js';

export const authRouter = Router();

authRouter.post('/register', AuthController.register);
authRouter.post('/login', AuthController.login);
authRouter.post('/refresh', AuthController.refresh);
authRouter.post('/logout', AuthController.logout);
authRouter.post('/forgot-password', AuthController.forgotPassword);

// Protected account management (F22)
authRouter.get('/export', authGuard, AuthController.exportData);
authRouter.delete('/account', authGuard, AuthController.deleteAccount);
