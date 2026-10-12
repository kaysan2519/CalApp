import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { AuthService } from './authService.js';

const registerSchema = z.object({
  email: z.string().email('Format email tidak valid'),
  password: z.string().min(8, 'Kata sandi minimal 8 karakter'),
  name: z.string().min(2, 'Nama minimal 2 karakter'),
  age: z.number().int().min(18, 'Usia minimal 18 tahun untuk menggunakan aplikasi.'),
  gender: z.enum(['male', 'female', 'neutral']).optional(),
  heightCm: z.number().min(100).max(250).optional(),
  weightKg: z.number().min(30).max(300).optional(),
  activityLevel: z.enum(['sedentary', 'light', 'moderate', 'heavy', 'very_heavy']).optional(),
  goal: z.enum(['lose', 'maintain', 'gain']).optional(),
  timezone: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email('Format email tidak valid'),
  password: z.string().min(1, 'Kata sandi wajib diisi'),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token wajib disertakan'),
});

export class AuthController {
  static async register(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = registerSchema.parse(req.body);
      const result = await AuthService.register(validated);
      res.status(201).json({
        success: true,
        data: result,
        message: 'Registrasi berhasil. Selamat datang di Cal!',
      });
    } catch (err) {
      next(err);
    }
  }

  static async login(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = loginSchema.parse(req.body);
      const result = await AuthService.login(validated.email, validated.password);
      res.json({
        success: true,
        data: result,
        message: 'Login berhasil.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async refresh(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = refreshSchema.parse(req.body);
      const result = await AuthService.refreshTokens(validated.refreshToken);
      res.json({
        success: true,
        data: result,
        message: 'Token berhasil diperbarui.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async logout(req: Request, res: Response, next: NextFunction) {
    try {
      const refreshToken = req.body.refreshToken;
      await AuthService.logout(refreshToken);
      res.json({
        success: true,
        message: 'Logout berhasil.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async exportData(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const data = await AuthService.exportUserData(userId);
      res.json({
        success: true,
        data,
        message: 'Ekspor data akun berhasil.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async deleteAccount(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      await AuthService.deleteAccount(userId);
      res.json({
        success: true,
        message: 'Akun dan seluruh data pribadi telah berhasil dihapus secara permanen.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async forgotPassword(req: Request, res: Response, next: NextFunction) {
    try {
      const email = req.body.email;
      // Mailer abstraction log
      console.log(`[Mailer] Reset password link simulated for ${email}`);
      res.json({
        success: true,
        message: 'Jika email terdaftar, tautan pengaturan ulang kata sandi telah dikirimkan.',
      });
    } catch (err) {
      next(err);
    }
  }
}
