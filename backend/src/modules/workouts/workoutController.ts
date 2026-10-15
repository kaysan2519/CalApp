import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { WorkoutService } from './workoutService.js';
import { routeParam } from '../../middleware/routeParam.js';

const startSessionSchema = z.object({
  title: z.string().min(2, 'Judul sesi minimal 2 karakter'),
  routineId: z.string().uuid().optional(),
});

const logSetSchema = z.object({
  exerciseId: z.string().uuid(),
  setNumber: z.number().int().positive(),
  reps: z.number().int().min(1),
  weightKg: z.number().min(0),
  rpe: z.number().min(1).max(10).optional(),
});

const finishSessionSchema = z.object({
  notes: z.string().optional(),
});

const createRoutineSchema = z.object({
  title: z.string().min(2),
  description: z.string().optional(),
  daysPerWeek: z.number().int().min(1).max(7).default(3),
  exercises: z.array(z.object({
    exerciseId: z.string().uuid(),
    targetSets: z.number().int().min(1).default(3),
    targetReps: z.number().int().min(1).default(10),
    restSeconds: z.number().int().min(15).default(90),
  })).min(1, 'Minimal 1 latihan dalam rutinitas'),
});

const aiGenSchema = z.object({
  goal: z.string().default('hypertrophy'),
  daysPerWeek: z.number().int().min(1).max(7).default(3),
  equipment: z.string().default('gym'),
});

export class WorkoutController {
  // --- Katalog Latihan ---
  static async getExercises(req: Request, res: Response, next: NextFunction) {
    try {
      const q = typeof req.query.q === 'string' ? req.query.q : undefined;
      const muscle = typeof req.query.muscle === 'string' ? req.query.muscle : undefined;
      const category = typeof req.query.category === 'string' ? req.query.category : undefined;
      const equipment = typeof req.query.equipment === 'string' ? req.query.equipment : undefined;

      const exercises = await WorkoutService.getExercises({ query: q, muscle, category, equipment });
      res.json({ success: true, data: exercises });
    } catch (err) {
      next(err);
    }
  }

  static async getExerciseById(req: Request, res: Response, next: NextFunction) {
    try {
      const exercise = await WorkoutService.getExerciseById(routeParam(req.params, 'id'));
      res.json({ success: true, data: exercise });
    } catch (err) {
      next(err);
    }
  }

  // --- Rutinitas Latihan ---
  static async getRoutines(req: Request, res: Response, next: NextFunction) {
    try {
      const routines = await WorkoutService.getRoutines(req.user!.id);
      res.json({ success: true, data: routines });
    } catch (err) {
      next(err);
    }
  }

  static async createRoutine(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createRoutineSchema.parse(req.body);
      const routine = await WorkoutService.createRoutine(req.user!.id, validated);
      res.status(201).json({ success: true, data: routine });
    } catch (err) {
      next(err);
    }
  }

  static async getRoutineById(req: Request, res: Response, next: NextFunction) {
    try {
      const routine = await WorkoutService.getRoutineById(req.user!.id, routeParam(req.params, 'id'));
      res.json({ success: true, data: routine });
    } catch (err) {
      next(err);
    }
  }

  // --- Live Sessions ---
  static async startSession(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = startSessionSchema.parse(req.body);
      const session = await WorkoutService.startSession(req.user!.id, validated);
      res.status(201).json({ success: true, data: session });
    } catch (err) {
      next(err);
    }
  }

  static async logSet(req: Request, res: Response, next: NextFunction) {
    try {
      const sessionId = routeParam(req.params, 'sessionId');
      const validated = logSetSchema.parse(req.body);
      const result = await WorkoutService.logSet(req.user!.id, sessionId, validated);
      res.status(201).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async finishSession(req: Request, res: Response, next: NextFunction) {
    try {
      const sessionId = routeParam(req.params, 'sessionId');
      const validated = finishSessionSchema.parse(req.body);
      const session = await WorkoutService.finishSession(req.user!.id, sessionId, validated.notes);
      res.json({ success: true, data: session });
    } catch (err) {
      next(err);
    }
  }

  static async getUserSessions(req: Request, res: Response, next: NextFunction) {
    try {
      const limit = req.query.limit ? Number(req.query.limit) : 20;
      const sessions = await WorkoutService.getUserSessions(req.user!.id, limit);
      res.json({ success: true, data: sessions });
    } catch (err) {
      next(err);
    }
  }

  static async getPersonalRecords(req: Request, res: Response, next: NextFunction) {
    try {
      const prs = await WorkoutService.getUserPersonalRecords(req.user!.id);
      res.json({ success: true, data: prs });
    } catch (err) {
      next(err);
    }
  }

  // --- F15: AI Workout Generator ---
  static async generateAIWorkout(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = aiGenSchema.parse(req.body);
      const result = await WorkoutService.generateAndSaveAIWorkout(
        req.user!.id,
        validated.goal,
        validated.daysPerWeek,
        validated.equipment
      );
      res.status(201).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }
}
