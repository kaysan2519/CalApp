import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { app } from '../src/app.js';
import { pool } from '../src/config/db.js';

describe('Backend Foundation & Health Check', () => {
  it('GET /api/v1/health returns healthy status', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('healthy');
    expect(res.body.data.app).toBe('Cal Backend API');
  });

  it('PostgreSQL connection is alive and can query current_timestamp', async () => {
    const res = await pool.query('SELECT NOW() as current_time');
    expect(res.rows.length).toBe(1);
    expect(res.rows[0].current_time).toBeDefined();
  });
});
