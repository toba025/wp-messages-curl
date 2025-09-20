#!/bin/bash

# Script para reiniciar correctamente el bot después de cambios de configuración

echo "🔄 Reiniciando WhatsApp Bot..."

# Detener todos los procesos PM2
echo "🛑 Deteniendo procesos PM2..."
pm2 stop all
pm2 delete all

# Limpiar procesos zombie
pm2 kill

# Verificar que no hay procesos corriendo
echo "🧹 Verificando que no hay procesos activos..."
pm2 status

# Esperar un momento
sleep 3

# Verificar que el display virtual está corriendo
echo "🖥️  Verificando display virtual..."
if ! pgrep -x "Xvfb" > /dev/null; then
    echo "⚠️  Iniciando display virtual..."
    export DISPLAY=:99
    Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
    sleep 3
    echo "✅ Display virtual iniciado"
else
    echo "✅ Display virtual ya está corriendo"
    export DISPLAY=:99
fi

# Verificar que estamos en el directorio correcto
echo "📁 Verificando directorio..."
if [ ! -f "server.js" ]; then
    echo "❌ Error: server.js no encontrado en $(pwd)"
    exit 1
fi

# Verificar que node_modules existe
if [ ! -d "node_modules" ]; then
    echo "❌ Error: node_modules no encontrado. Ejecuta npm install primero"
    exit 1
fi

# Crear directorio de logs si no existe
mkdir -p logs

# Iniciar el bot con la nueva configuración
echo "🚀 Iniciando bot con nueva configuración..."
pm2 start ecosystem.config.js

# Esperar un momento para que se inicie
sleep 5

# Verificar estado
echo "📊 Estado del bot:"
pm2 status

# Mostrar logs recientes
echo "📝 Logs recientes:"
pm2 logs whatsapp-bot --lines 10

echo "✅ Reinicio completado!"
echo ""
echo "📋 Comandos útiles:"
echo "  - Ver estado: pm2 status"
echo "  - Ver logs: pm2 logs whatsapp-bot"
echo "  - Monitor: pm2 monit"
echo "  - Probar API: curl http://localhost:8002/status"
