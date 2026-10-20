import os from 'os';
import { app } from './app.js';
import { pool } from './config/db.js';
import { config } from './config/env.js';
import { runMigrations } from './db/migrate.js';

function getLocalIp(): string {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const net of interfaces[name] || []) {
      if (net.family === 'IPv4' && !net.internal && !net.address.startsWith('169.254')) {
        return net.address;
      }
    }
  }
  return 'localhost';
}

async function startServer() {
  console.log(`\n======================================================`);
  console.log(`  🚀 Menyalakan Cal Backend API Engine (${config.nodeEnv})`);
  console.log(`======================================================`);

  // 1. Verify PostgreSQL connection
  try {
    const dbRes = await pool.query('SELECT current_database(), current_user, version()');
    const dbName = dbRes.rows[0].current_database;
    const dbUser = dbRes.rows[0].current_user;
    console.log(`[Database] Terhubung ke PostgreSQL: '${dbName}' sebagai user '${dbUser}'.`);
  } catch (err: any) {
    console.error(`[Database Error] Gagal terhubung ke PostgreSQL: ${err.message}`);
    console.error(`Pastikan service PostgreSQL berjalan di port ${config.db.port}.`);
  }

  // 2. Auto-run migrations if tables missing
  try {
    const tableCheck = await pool.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users'"
    );
    if (tableCheck.rowCount === 0) {
      console.log(`[Database] Tabel 'users' belum ditemukan. Menjalankan migrasi otomatis...`);
      await runMigrations();
    }
  } catch (err: any) {
    console.warn(`[Database] Pengecekan tabel migrasi: ${err.message}`);
  }

  // 3. Start listening on all network interfaces (0.0.0.0)
  const host = '0.0.0.0';
  const server = app.listen(config.port, host, () => {
    const localIp = getLocalIp();
    console.log(`\n[Cal Server] Aktif & Mendengarkan di Semua Antarmuka (${host}):`);
    console.log(`  - Local:           http://localhost:${config.port}/api/v1`);
    console.log(`  - Local IPv4:      http://127.0.0.1:${config.port}/api/v1`);
    console.log(`  - Android Emu:     http://10.0.2.2:${config.port}/api/v1`);
    console.log(`  - Wi-Fi / HP Fisik: http://${localIp}:${config.port}/api/v1`);
    console.log(`  - Health Check:    http://localhost:${config.port}/api/v1/health\n`);
    console.log(`[Cal Server] Backend siap melayani aplikasi Flutter & Web!`);
  });

  server.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`[Cal Server Error] Port ${config.port} sudah digunakan oleh proses lain!`);
    } else {
      console.error(`[Cal Server Error]`, err);
    }
  });

  // Graceful shutdown
  const shutdown = async () => {
    console.log('\n[Cal Server] Mematikan server secara graceful...');
    server.close(async () => {
      await pool.end();
      console.log('[Cal Server] Server dan koneksi database ditutup dengan aman.');
      process.exit(0);
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

process.on('unhandledRejection', (reason) => {
  console.error('[Cal Server] Unhandled Promise Rejection:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('[Cal Server] Uncaught Exception:', err);
});

startServer();
