import { Router } from 'express';
import { WorkoutController } from './workoutController.js';
import { authGuard } from '../../middleware/authGuard.js';

export const workoutRouter = Router();

workoutRouter.use(authGuard);

// F13: Katalog Latihan
workoutRouter.get('/exercises', WorkoutController.getExercises);
workoutRouter.get('/exercises/:id', WorkoutController.getExerciseById);

// F14: Rutinitas & Program Latihan
workoutRouter.get('/routines', WorkoutController.getRoutines);
workoutRouter.post('/routines', WorkoutController.createRoutine);
workoutRouter.get('/routines/:id', WorkoutController.getRoutineById);

// F13: Sesi Workout Live & Logging Set
workoutRouter.get('/sessions', WorkoutController.getUserSessions);
workoutRouter.post('/sessions', WorkoutController.startSession);
workoutRouter.post('/sessions/:sessionId/sets', WorkoutController.logSet);
workoutRouter.put('/sessions/:sessionId/finish', WorkoutController.finishSession);
workoutRouter.get('/personal-records', WorkoutController.getPersonalRecords);

// F15: AI Workout Generator
workoutRouter.post('/ai-generate', WorkoutController.generateAIWorkout);
