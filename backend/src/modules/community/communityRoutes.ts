import { Router } from 'express';
import { authGuard } from '../../middleware/authGuard.js';
import { communityController } from './communityController.js';

const router = Router();

router.use(authGuard);

// Groups
router.get('/groups', (req, res) => communityController.listGroups(req, res));
router.post('/groups', (req, res) => communityController.createGroup(req, res));
router.post('/groups/:id/join', (req, res) => communityController.joinGroup(req, res));
router.post('/groups/:id/leave', (req, res) => communityController.leaveGroup(req, res));

// Posts & Feed
router.get('/posts', (req, res) => communityController.listPosts(req, res));
router.post('/posts', (req, res) => communityController.createPost(req, res));

// Reactions & Comments
router.post('/posts/:id/reactions', (req, res) => communityController.toggleReaction(req, res));
router.get('/posts/:id/comments', (req, res) => communityController.listComments(req, res));
router.post('/posts/:id/comments', (req, res) => communityController.addComment(req, res));

// Moderation
router.post('/report', (req, res) => communityController.reportContent(req, res));

export default router;
