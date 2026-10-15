import dotenv from 'dotenv';
dotenv.config();

const nodeEnv = process.env.NODE_ENV || 'development';
const jwtSecret = process.env.JWT_SECRET || (nodeEnv === 'production' ? '' : 'dev_jwt_secret_key_cal_app_2026');
const jwtRefreshSecret = process.env.JWT_REFRESH_SECRET || (nodeEnv === 'production' ? '' : 'dev_jwt_refresh_secret_cal_app_2026');

if (nodeEnv === 'production' && (jwtSecret.length < 32 || jwtRefreshSecret.length < 32)) {
  throw new Error('JWT_SECRET and JWT_REFRESH_SECRET must each be at least 32 characters in production.');
}

export const config = {
  port: parseInt(process.env.PORT || '4000', 10),
  nodeEnv,
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
    database: process.env.NODE_ENV === 'test' 
      ? (process.env.TEST_DB_NAME || 'cal_test') 
      : (process.env.DB_NAME || 'cal_dev'),
  },
  jwt: {
    secret: jwtSecret,
    refreshSecret: jwtRefreshSecret,
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },
  ai: {
    openaiKey: process.env.OPENAI_API_KEY,
    provider: process.env.AI_PROVIDER || 'openai',
    openaiModel: process.env.OPENAI_MODEL || 'gpt-4o-mini',
    timeoutMs: Number.parseInt(process.env.AI_TIMEOUT_MS || '25000', 10),
  },
};
