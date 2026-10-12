import { Router } from 'express';
import { authGuard } from '../../middleware/authGuard.js';
import { gamificationController } from './gamificationController.js';

const router = Router();

router.use(authGuard);

router.get('/profile', (req, res) => gamificationController.getProfile(req, res));
router.get('/achievements', (req, res) => gamificationController.getAchievements(req, res));
router.get('/leaderboard', (req, res) => gamificationController.getLeaderboard(req, res));
router.get('/challenges', (req, res) => gamificationController.getChallenges(req, res));
router.post('/award-xp', (req, res) => gamificationController.awardXp(req, res));

export default router;
