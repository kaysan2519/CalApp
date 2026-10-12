import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { errorHandler } from './middleware/errorHandler.js';
import { authRouter } from './modules/auth/authRoutes.js';
import { profileRouter } from './modules/profile/profileRoutes.js';
import { nutritionRouter } from './modules/nutrition/nutritionRoutes.js';
import { aiRouter } from './modules/ai/aiRoutes.js';
import { recipeRouter } from './modules/recipes/recipeRoutes.js';
import { plannerRouter } from './modules/recipes/plannerRoutes.js';
import { workoutRouter } from './modules/workouts/workoutRoutes.js';
import { bodyRouter } from './modules/workouts/bodyRoutes.js';

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health Check
app.get('/api/v1/health', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'healthy',
      app: 'Cal Backend API',
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

// Global error handler
app.use(errorHandler);
