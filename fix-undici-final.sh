#!/bin/bash

# Script final para solucionar el problema de undici con Node.js 18
# Este script instala versiones específicas compatibles

echo "🔧 Solucionando problema final de undici..."

# Detener PM2
echo "🛑 Deteniendo PM2..."
pm2 stop all
pm2 delete all

# Verificar versión de Node.js
echo "📋 Versión de Node.js: $(node --version)"

# Limpiar completamente
echo "🧹 Limpiando completamente..."
rm -rf node_modules package-lock.json
npm cache clean --force

# Crear package.json temporal con versiones específicas
echo "📦 Instalando versiones específicas compatibles..."

# Instalar versiones que funcionan con Node.js 18
npm install express@4.18.2
npm install body-parser@1.20.2
npm install puppeteer@21.5.2

# Instalar venom-bot con versión específica
npm install venom-bot@5.0.9

# Forzar instalación de undici compatible
npm install undici@5.28.4 --save

# Crear .npmrc
cat > .npmrc << 'EOF'
legacy-peer-deps=true
fund=false
audit=false
EOF

# Reinstalar todo
npm install

# Verificar que undici se instaló correctamente
echo "✅ Verificando instalación de undici..."
npm list undici

# Crear archivo de configuración para puppeteer
mkdir -p .puppeteer
cat > .puppeteer/config.json << 'EOF'
{
  "cacheDirectory": "/tmp/puppeteer_cache"
}
EOF

# Configurar variables de entorno
export PUPPETEER_CACHE_DIR="/tmp/puppeteer_cache"
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Crear directorio de cache
mkdir -p /tmp/puppeteer_cache

echo "🎯 Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Reiniciar el bot: pm2 start ecosystem.config.js"
echo "2. Verificar logs: pm2 logs whatsapp-bot"
echo "3. Probar API: curl http://localhost:8002/status"
echo ""
echo "✅ Si el error persiste, ejecuta:"
echo "   npm install undici@5.28.4 --force"
