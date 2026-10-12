import { Request, Response } from 'express';
import { communityService } from './communityService.js';

export class CommunityController {
  // Groups
  async createGroup(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const { name, description, isPrivate } = req.body;
      if (!name) {
        return res.status(400).json({ status: 'error', message: 'Nama grup wajib diisi' });
      }

      const group = await communityService.createGroup(userId, name, description, !!isPrivate);
      return res.status(201).json({ status: 'success', data: group });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  async listGroups(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const groups = await communityService.listGroups(userId);
      return res.json({ status: 'success', data: groups });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  async joinGroup(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const { id: groupId } = req.params;
      const member = await communityService.joinGroup(userId, groupId);
      return res.json({ status: 'success', data: member });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  async leaveGroup(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const { id: groupId } = req.params;
      const result = await communityService.leaveGroup(userId, groupId);
      return res.json({ status: 'success', data: result });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  // Posts
  async createPost(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const { content, groupId, postType, metadata } = req.body;
      if (!content) {
        return res.status(400).json({ status: 'error', message: 'Konten postingan wajib diisi' });
      }

      const post = await communityService.createPost(
        userId,
        content,
        groupId,
        postType || 'text',
        metadata || {}
      );
      return res.status(201).json({ status: 'success', data: post });
    } catch (error: any) {
      return res.status(400).json({ status: 'error', message: error.message });
    }
  }

  async listPosts(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const groupId = req.query.groupId as string | undefined;
      const limit = parseInt(req.query.limit as string, 10) || 20;
      const offset = parseInt(req.query.offset as string, 10) || 0;

      const posts = await communityService.listPosts(userId, groupId, limit, offset);
      return res.json({ status: 'success', data: posts });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  // Reactions
  async toggleReaction(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const { id: postId } = req.params;
      const { reactionType } = req.body;

      const result = await communityService.toggleReaction(userId, postId, reactionType || 'kudos');
      return res.json({ status: 'success', data: result });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  // Comments
  async addComment(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const { id: postId } = req.params;
      const { content } = req.body;

      if (!content) {
        return res.status(400).json({ status: 'error', message: 'Komentar tidak boleh kosong' });
      }

      const comment = await communityService.addComment(userId, postId, content);
      return res.status(201).json({ status: 'success', data: comment });
    } catch (error: any) {
      return res.status(400).json({ status: 'error', message: error.message });
    }
  }

  async listComments(req: Request, res: Response) {
    try {
      const { id: postId } = req.params;
      const comments = await communityService.listComments(postId);
      return res.json({ status: 'success', data: comments });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  // Moderation & Report
  async reportContent(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const { reason, targetPostId, targetUserId } = req.body;

      if (!reason) {
        return res.status(400).json({ status: 'error', message: 'Alasan pelaporan wajib disertakan' });
      }

      const result = await communityService.reportContent(userId, reason, targetPostId, targetUserId);
      return res.json({ status: 'success', data: result });
    } catch (error: any) {
      return res.status(400).json({ status: 'error', message: error.message });
    }
  }
}

export const communityController = new CommunityController();
