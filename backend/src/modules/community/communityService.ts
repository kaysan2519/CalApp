import { pool } from '../../config/db.js';
import { gamificationService } from '../gamification/gamificationService.js';

export class CommunityService {
  /**
   * Create a community group
   */
  async createGroup(ownerId: string, name: string, description?: string, isPrivate = false) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const res = await client.query(
        `INSERT INTO groups (name, description, is_private, owner_id)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [name, description || null, isPrivate, ownerId]
      );
      const group = res.rows[0];

      // Automatically add owner as group owner member
      await client.query(
        `INSERT INTO group_members (group_id, user_id, role)
         VALUES ($1, $2, 'owner')`,
        [group.id, ownerId]
      );

      await client.query('COMMIT');
      return group;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * List groups with member count & user membership status
   */
  async listGroups(userId: string) {
    const res = await pool.query(
      `SELECT g.id, g.name, g.description, g.is_private, g.created_at,
              COUNT(gm.id) as member_count,
              EXISTS(SELECT 1 FROM group_members gm2 WHERE gm2.group_id = g.id AND gm2.user_id = $1) as is_member
       FROM groups g
       LEFT JOIN group_members gm ON g.id = gm.group_id
       GROUP BY g.id
       ORDER BY member_count DESC, g.name ASC`,
      [userId]
    );

    return res.rows.map((r) => ({
      ...r,
      member_count: parseInt(r.member_count, 10) || 0,
    }));
  }

  /**
   * Join group
   */
  async joinGroup(userId: string, groupId: string) {
    const res = await pool.query(
      `INSERT INTO group_members (group_id, user_id, role)
       VALUES ($1, $2, 'member')
       ON CONFLICT (group_id, user_id) DO UPDATE SET joined_at = NOW()
       RETURNING *`,
      [groupId, userId]
    );
    return res.rows[0];
  }

  /**
   * Leave group
   */
  async leaveGroup(userId: string, groupId: string) {
    await pool.query(
      `DELETE FROM group_members WHERE group_id = $1 AND user_id = $2`,
      [groupId, userId]
    );
    return { success: true };
  }

  /**
   * Create a community feed post (text, meal share, or workout share)
   */
  async createPost(
    userId: string,
    content: string,
    groupId?: string,
    postType = 'text',
    metadata: Record<string, unknown> = {}
  ) {
    if (!content || content.trim().length === 0) {
      throw new Error('Konten postingan tidak boleh kosong');
    }
    if (content.length > 2000) {
      throw new Error('Panjang postingan maksimal 2000 karakter');
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const res = await client.query(
        `INSERT INTO community_posts (user_id, group_id, content, post_type, metadata)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [userId, groupId || null, content.trim(), postType, JSON.stringify(metadata)]
      );
      const post = res.rows[0];

      await client.query('COMMIT');

      // Award +15 XP for community sharing (idempotent with post ID)
      try {
        await gamificationService.awardXp(
          userId,
          'community_post',
          15,
          `post_${post.id}`,
          { postId: post.id }
        );
      } catch (_) {
        // Non-blocking for post creation
      }

      return post;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * List community posts feed with author info, kudos count, and user reaction status
   */
  async listPosts(userId: string, groupId?: string, limit = 20, offset = 0) {
    const params: any[] = [userId, limit, offset];
    let groupCondition = '';
    if (groupId) {
      params.push(groupId);
      groupCondition = `WHERE cp.group_id = $4`;
    }

    const query = `
      SELECT cp.id, cp.user_id, cp.group_id, cp.content, cp.post_type, cp.metadata, cp.created_at,
             u.name as author_name,
             g.name as group_name,
             COUNT(DISTINCT cr.id) as reaction_count,
             COUNT(DISTINCT cc.id) as comment_count,
             EXISTS(
               SELECT 1 FROM community_reactions cr2
               WHERE cr2.post_id = cp.id AND cr2.user_id = $1
             ) as has_reacted
      FROM community_posts cp
      JOIN users u ON cp.user_id = u.id
      LEFT JOIN groups g ON cp.group_id = g.id
      LEFT JOIN community_reactions cr ON cp.id = cr.post_id
      LEFT JOIN community_comments cc ON cp.id = cc.post_id
      ${groupCondition}
      GROUP BY cp.id, u.name, g.name
      ORDER BY cp.created_at DESC
      LIMIT $2 OFFSET $3;
    `;

    const res = await pool.query(query, params);
    return res.rows.map((r) => ({
      ...r,
      reaction_count: parseInt(r.reaction_count, 10) || 0,
      comment_count: parseInt(r.comment_count, 10) || 0,
    }));
  }

  /**
   * Toggle reaction (kudos / applause)
   */
  async toggleReaction(userId: string, postId: string, reactionType = 'kudos') {
    const existing = await pool.query(
      `SELECT id FROM community_reactions WHERE post_id = $1 AND user_id = $2 AND reaction_type = $3`,
      [postId, userId, reactionType]
    );

    if (existing.rows.length > 0) {
      // Remove reaction
      await pool.query(
        `DELETE FROM community_reactions WHERE post_id = $1 AND user_id = $2 AND reaction_type = $3`,
        [postId, userId, reactionType]
      );
      return { reacted: false, reactionType };
    } else {
      // Add reaction
      await pool.query(
        `INSERT INTO community_reactions (post_id, user_id, reaction_type)
         VALUES ($1, $2, $3)`,
        [postId, userId, reactionType]
      );
      return { reacted: true, reactionType };
    }
  }

  /**
   * Add comment to post
   */
  async addComment(userId: string, postId: string, content: string) {
    if (!content || content.trim().length === 0) {
      throw new Error('Komentar tidak boleh kosong');
    }

    const res = await pool.query(
      `INSERT INTO community_comments (post_id, user_id, content)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [postId, userId, content.trim()]
    );

    const author = await pool.query(
      `SELECT name as author_name FROM users WHERE id = $1`,
      [userId]
    );

    return {
      ...res.rows[0],
      author_name: author.rows[0]?.author_name || 'Sahabat Cal',
    };
  }

  /**
   * List comments of a post
   */
  async listComments(postId: string) {
    const res = await pool.query(
      `SELECT cc.id, cc.post_id, cc.user_id, cc.content, cc.created_at,
              u.name as author_name
       FROM community_comments cc
       JOIN users u ON cc.user_id = u.id
       WHERE cc.post_id = $1
       ORDER BY cc.created_at ASC`,
      [postId]
    );
    return res.rows;
  }

  /**
   * Report content or user for safety & moderation
   */
  async reportContent(
    reporterId: string,
    reason: string,
    targetPostId?: string,
    targetUserId?: string
  ) {
    if (!reason || reason.trim().length === 0) {
      throw new Error('Alasan pelaporan harus disertakan');
    }

    const res = await pool.query(
      `INSERT INTO reports_blocks (reporter_id, target_post_id, target_user_id, reason, status)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING *`,
      [reporterId, targetPostId || null, targetUserId || null, reason.trim()]
    );

    return {
      reported: true,
      reportId: res.rows[0].id,
      message: 'Laporan Anda telah diterima dan akan ditinjau tim moderasi dalam 24 jam.',
    };
  }
}

export const communityService = new CommunityService();
