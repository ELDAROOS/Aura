#!/bin/bash

# Настройки
APP_NAME="Aura"
APP_PATH="./build_output/Build/Products/Release/${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
VOL_NAME="${APP_NAME} Installer"

echo "🚀 Начинаю создание DMG для ${APP_NAME}..."

# 1. Проверяем, собрано ли приложение
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Ошибка: Приложение не найдено по пути ${APP_PATH}"
    echo "Сначала собери проект в Xcode (Product -> Archive) или укажи правильный путь."
    exit 1
fi

# 2. Очищаем старый DMG если он есть
if [ -f "$DMG_NAME" ]; then
    rm "$DMG_NAME"
fi

# 3. Создаем временную папку для образа
mkdir -p ./dist
cp -R "$APP_PATH" ./dist/
ln -s /Applications ./dist/Applications

# 4. Создаем DMG
echo "📦 Упаковываю в образ..."
hdiutil create -volname "$VOL_NAME" -srcfolder ./dist -ov -format UDZO "$DMG_NAME"

# 5. Очистка
rm -rf ./dist

echo "✅ Готово! Твой файл тут: $(pwd)/$DMG_NAME"
