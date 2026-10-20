import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { pool } from './config/db.js';
import { config } from './config/env.js';
import { errorHandler } from './middleware/errorHandler.js';
import { authRouter } from './modules/auth/authRoutes.js';
import { profileRouter } from './modules/profile/profileRoutes.js';
import { nutritionRouter } from './modules/nutrition/nutritionRoutes.js';
import { aiRouter } from './modules/ai/aiRoutes.js';
import { recipeRouter } from './modules/recipes/recipeRoutes.js';
import { plannerRouter } from './modules/recipes/plannerRoutes.js';
import { workoutRouter } from './modules/workouts/workoutRoutes.js';
import { bodyRouter } from './modules/workouts/bodyRoutes.js';
import gamificationRouter from './modules/gamification/gamificationRoutes.js';
import communityRouter from './modules/community/communityRoutes.js';
import notificationRouter from './modules/notifications/notificationRoutes.js';
import insightRouter from './modules/insights/insightRoutes.js';

export const app = express();

app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Development request logger
if (config.nodeEnv !== 'test') {
  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      const status = res.statusCode;
      const color = status >= 500 ? '\x1b[31m' : status >= 400 ? '\x1b[33m' : '\x1b[32m';
      console.log(`[API] ${req.method} ${req.originalUrl} ${color}${status}\x1b[0m (${duration}ms)`);
    });
    next();
  });
}

// Health Check with live DB connectivity check
app.get('/api/v1/health', async (req, res) => {
  let dbStatus = 'disconnected';
  try {
    await pool.query('SELECT 1');
    dbStatus = 'connected';
  } catch (err: any) {
    dbStatus = `error: ${err.message}`;
  }

  res.json({
    success: true,
    data: {
      status: 'healthy',
      app: 'Cal Backend API',
      database: dbStatus,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    },
  });
});

// Routes
app.use('/api/v1/auth', authRouter);
app.use('/api/v1/profile', profileRouter);
app.use('/api/v1/nutrition', nutritionRouter);
app.use('/api/v1/ai', aiRouter);
app.use('/api/v1/recipes', recipeRouter);
app.use('/api/v1/planner', plannerRouter);
app.use('/api/v1/workouts', workoutRouter);
app.use('/api/v1/body', bodyRouter);
app.use('/api/v1/gamification', gamificationRouter);
app.use('/api/v1/community', communityRouter);
app.use('/api/v1/notifications', notificationRouter);
app.use('/api/v1/insights', insightRouter);

// Global error handler
app.use(errorHandler);
