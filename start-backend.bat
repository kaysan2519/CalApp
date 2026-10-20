@echo off
title Cal App - Backend API Server (Port 4000)
color 0A
echo ======================================================
echo    CAL FITNESS APP - BACKEND SERVER LAUNCHER
echo ======================================================
echo.
echo [1/2] Memeriksa direktori backend...
cd /d "%~dp0backend"
echo [2/2] Menjalankan server Node.js / Express (Port 4000)...
echo.
echo Server akan aktif di:
echo   - Local:   http://localhost:4000/api/v1
echo   - IP Loop: http://127.0.0.1:4000/api/v1
echo   - Health:  http://127.0.0.1:4000/api/v1/health
echo.
echo Tekan Ctrl+C jika ingin mematikan server.
echo ------------------------------------------------------
call npm run dev
pause
