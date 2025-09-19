#!/bin/bash


echo "🚀 Iniciando WhatsApp Bot..."

if ! pgrep -x "Xvfb" > /dev/null; then
    echo "🖥️  Iniciando display virtual Xvfb..."
    Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
    export DISPLAY=:99
    sleep 3
else
    echo "✅ Display virtual ya está corriendo"
    export DISPLAY=:99
fi

if [ -f "/usr/bin/google-chrome-stable" ]; then
    echo "✅ Google Chrome encontrado"
elif [ -f "/usr/bin/chromium-browser" ]; then
    echo "✅ Chromium encontrado"
else
    echo "❌ Error: No se encontró Chrome ni Chromium instalado"
    echo "Ejecuta primero: sudo bash install-dependencies.sh"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js no está instalado"
    echo "Ejecuta primero: sudo bash install-dependencies.sh"
    exit 1
fi

cd "$(dirname "$0")"

if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias de Node.js..."
    npm install
fi

mkdir -p logs

echo "🎯 Iniciando servidor..."
echo "📱 El bot estará disponible en: http://localhost:8002"
echo "📋 Endpoints disponibles:"
echo "  - POST /send-message"
echo "  - GET /status"
echo ""
echo "⚠️  Para detener el bot, presiona Ctrl+C"

node server.js
