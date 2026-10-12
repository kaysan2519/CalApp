import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app.js';
import { pool } from '../src/config/db.js';

describe('Phase 8 - Gamification, Community & Notifications Integration', () => {
  let authToken: string;
  let userId: string;
  let testGroupId: string;
  let testPostId: string;

  beforeAll(async () => {
    // Register unique user
    const email = `gamify_${Date.now()}@example.com`;
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email,
        password: 'Password123!',
        name: 'Budi Gamifier',
        age: 25,
      });

    expect(res.status).toBe(201);
    authToken = res.body.data.accessToken;
    userId = res.body.data.user.id;
  });

  describe('F16: XP, Leveling & Achievements', () => {
    it('awards XP to user and calculates level progressively', async () => {
      const idempotencyKey = `award_${Date.now()}_1`;
      const res = await request(app)
        .post('/api/v1/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          eventCode: 'log_meal',
          xpAmount: 50,
          idempotencyKey,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.awarded).toBe(true);
      expect(res.body.data.xpAmount).toBe(50);
      expect(res.body.data.totalXp).toBe(50);
      expect(res.body.data.currentLevel).toBe(1);
    });

    it('enforces idempotency on same event key without duplicate XP', async () => {
      const idempotencyKey = `award_duplicate_test_${Date.now()}`;

      // First call
      const res1 = await request(app)
        .post('/api/v1/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          eventCode: 'log_workout',
          xpAmount: 25,
          idempotencyKey,
        });
      expect(res1.body.data.awarded).toBe(true);
      const totalXpAfterFirst = res1.body.data.totalXp;

      // Duplicate call
      const res2 = await request(app)
        .post('/api/v1/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          eventCode: 'log_workout',
          xpAmount: 25,
          idempotencyKey,
        });
      expect(res2.body.data.awarded).toBe(false);
      expect(res2.body.data.reason).toBe('duplicate_event');
      expect(res2.body.data.totalXp).toBe(totalXpAfterFirst);
    });

    it('enforces daily XP cap of 500 XP strictly', async () => {
      const idempotencyKey = `award_cap_test_${Date.now()}`;
      // Request huge amount
      const res = await request(app)
        .post('/api/v1/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          eventCode: 'bonus_event',
          xpAmount: 600,
          idempotencyKey,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.dailyXpEarned).toBeLessThanOrEqual(500);

      // Subsequent award on same day should be capped
      const resCapped = await request(app)
        .post('/api/v1/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          eventCode: 'another_bonus',
          xpAmount: 50,
          idempotencyKey: `award_over_cap_${Date.now()}`,
        });

      expect(resCapped.status).toBe(200);
      expect(resCapped.body.data.awarded).toBe(false);
      expect(resCapped.body.data.reason).toBe('daily_cap_reached');
      expect(resCapped.body.data.dailyCapReached).toBe(true);
    });

    it('fetches gamification profile and achievements list', async () => {
      const resProfile = await request(app)
        .get('/api/v1/gamification/profile')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resProfile.status).toBe(200);
      expect(resProfile.body.data.totalXp).toBeGreaterThanOrEqual(500);
      expect(resProfile.body.data.currentLevel).toBeGreaterThanOrEqual(2);
      expect(resProfile.body.data.dailyXpCap).toBe(500);

      const resAch = await request(app)
        .get('/api/v1/gamification/achievements')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resAch.status).toBe(200);
      expect(Array.isArray(resAch.body.data)).toBe(true);
      expect(resAch.body.data.length).toBeGreaterThan(0);
    });
  });

  describe('F17: Leaderboard & Challenges', () => {
    it('returns weekly leaderboard with rank and canonical timezone Asia/Jakarta', async () => {
      const res = await request(app)
        .get('/api/v1/gamification/leaderboard')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.period).toBe('weekly');
      expect(res.body.data.canonicalTimezone).toBe('Asia/Jakarta');
      expect(Array.isArray(res.body.data.leaderboard)).toBe(true);
      expect(res.body.data.currentUserRank).toBeDefined();
    });

    it('returns active challenges catalog', async () => {
      const res = await request(app)
        .get('/api/v1/gamification/challenges')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  describe('F18: Community Groups, Posts, Reactions & Moderation', () => {
    it('creates community group and lists available groups', async () => {
      const resCreate = await request(app)
        .post('/api/v1/community/groups')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Pejuang Defisit Santai',
          description: 'Grup saling menyemangati pola makan seimbang tanpa stres',
          isPrivate: false,
        });

      expect(resCreate.status).toBe(201);
      testGroupId = resCreate.body.data.id;
      expect(resCreate.body.data.name).toBe('Pejuang Defisit Santai');

      const resList = await request(app)
        .get('/api/v1/community/groups')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resList.status).toBe(200);
      expect(resList.body.data.some((g: any) => g.id === testGroupId)).toBe(true);
    });

    it('creates a feed post and lists posts with kudos and author info', async () => {
      const resPost = await request(app)
        .post('/api/v1/community/posts')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Hari ini berhasil capai target 1800 kkal dan 110g protein! Tetap semangat kawan-kawan.',
          groupId: testGroupId,
          postType: 'text',
        });

      expect(resPost.status).toBe(201);
      testPostId = resPost.body.data.id;

      const resFeed = await request(app)
        .get('/api/v1/community/posts')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resFeed.status).toBe(200);
      expect(resFeed.body.data.length).toBeGreaterThan(0);
      const post = resFeed.body.data.find((p: any) => p.id === testPostId);
      expect(post).toBeDefined();
      expect(post.author_name).toBeDefined();
    });

    it('toggles reaction (kudos) and adds comments', async () => {
      // Toggle reaction ON
      const resReactOn = await request(app)
        .post(`/api/v1/community/posts/${testPostId}/reactions`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ reactionType: 'kudos' });

      expect(resReactOn.status).toBe(200);
      expect(resReactOn.body.data.reacted).toBe(true);

      // Add comment
      const resComment = await request(app)
        .post(`/api/v1/community/posts/${testPostId}/comments`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ content: 'Luar biasa bro, pertahankan konsistensinya!' });

      expect(resComment.status).toBe(201);
      expect(resComment.body.data.content).toBe('Luar biasa bro, pertahankan konsistensinya!');

      // List comments
      const resCommentList = await request(app)
        .get(`/api/v1/community/posts/${testPostId}/comments`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(resCommentList.status).toBe(200);
      expect(resCommentList.body.data.length).toBeGreaterThan(0);
    });

    it('reports content safely to moderation queue', async () => {
      const resReport = await request(app)
        .post('/api/v1/community/report')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          targetPostId: testPostId,
          reason: 'Uji coba sistem pelaporan konten pantas',
        });

      expect(resReport.status).toBe(200);
      expect(resReport.body.data.reported).toBe(true);
      expect(resReport.body.data.reportId).toBeDefined();
    });
  });

  describe('F21: Gentle Non-shaming Notification Preferences', () => {
    it('reads and updates notification reminder preferences', async () => {
      const resGet = await request(app)
        .get('/api/v1/notifications/preferences')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resGet.status).toBe(200);
      expect(resGet.body.data.preferences.gentleTone).toBe(true);
      expect(resGet.body.data.scheduledReminders.length).toBeGreaterThan(0);

      // Update preferences
      const resPut = await request(app)
        .put('/api/v1/notifications/preferences')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          breakfastTime: '07:00',
          waterIntervalHours: 3,
        });

      expect(resPut.status).toBe(200);
      expect(resPut.body.data.breakfastTime).toBe('07:00');
      expect(resPut.body.data.waterIntervalHours).toBe(3);
    });
  });
});
