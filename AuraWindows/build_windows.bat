@echo off
echo 🚀 Aura Windows Build System
echo ---------------------------

:: Проверка наличия Swift
where swift >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Ошибка: Swift не найден. Установи его с swift.org
    pause
    exit /b
)

echo 📦 Собираю проект Aura...
swift build -c release

if %errorlevel% equ 0 (
    echo.
    echo ✅ Готово! Твой файл Aura.exe находится в папке:
    echo .build\release\Aura.exe
) else (
    echo ❌ Ошибка при сборке.
)

pause
