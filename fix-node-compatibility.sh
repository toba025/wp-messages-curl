#!/bin/bash


echo "🔧 Solucionando problemas de compatibilidad de Node.js..."

echo "📋 Verificando versión de Node.js..."
node --version
npm --version

echo "🛑 Deteniendo procesos PM2..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

echo "🧹 Limpiando cache de npm..."
npm cache clean --force

echo "📦 Reinstalando dependencias con versiones compatibles..."

rm -rf node_modules package-lock.json

npm install express@4.18.2
npm install body-parser@1.20.2
npm install venom-bot@5.0.9
npm install puppeteer@21.5.2

cat > .npmrc << 'EOF'
legacy-peer-deps=true
fund=false
audit=false
EOF

npm install

echo "✅ Verificando instalación..."
npm list --depth=0

echo "🎯 Solucionando problemas específicos de venom-bot..."

mkdir -p .puppeteer
cat > .puppeteer/config.json << 'EOF'
{
  "cacheDirectory": "/tmp/puppeteer_cache"
}
EOF

export PUPPETEER_CACHE_DIR="/tmp/puppeteer_cache"
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

mkdir -p /tmp/puppeteer_cache

echo "✅ Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Reiniciar el bot: ./pm2-manager.sh start"
echo "2. Verificar logs: ./pm2-manager.sh logs"
echo "3. Si persiste el error, ejecutar: node --version"
echo ""
echo "🔍 Si el problema persiste, puede ser necesario:"
echo "- Usar Node.js 18.x en lugar de 20.x"
echo "- O actualizar a versiones más recientes de las dependencias"
