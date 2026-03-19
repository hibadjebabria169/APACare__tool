@echo off
echo ====================================
echo APACare Backend - LLM + KG Service
echo ====================================

cd /d "%~dp0"

echo.
echo Installing dependencies...
pip install -r requirements.txt

echo.
echo Starting server on http://localhost:8000
echo.
echo API Endpoints:
echo   GET  /           - Service info
echo   GET  /health     - Health check
echo   POST /recommendations - Get recommendations
echo.

python main.py
