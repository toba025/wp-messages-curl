#!/bin/bash

# Script para mantener Node.js 20 y solucionar el problema de undici
# Este script usa versiones específicas de dependencias compatibles

echo "🔧 Solucionando compatibilidad con Node.js 20..."

# Detener PM2
echo "🛑 Deteniendo PM2..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Verificar versión de Node.js
echo "📋 Versión de Node.js: $(node --version)"

# Limpiar dependencias
echo "🧹 Limpiando dependencias..."
rm -rf node_modules package-lock.json
npm cache clean --force

# Crear package.json temporal con versiones específicas
echo "📦 Instalando versiones específicas compatibles..."

# Instalar versiones específicas que funcionan con Node.js 20
npm install express@4.18.2
npm install body-parser@1.20.2
npm install venom-bot@5.0.9
npm install puppeteer@21.5.2

# Crear .npmrc
cat > .npmrc << 'EOF'
legacy-peer-deps=true
fund=false
audit=false
EOF

# Reinstalar todo
npm install

# Crear archivo de configuración para puppeteer
mkdir -p .puppeteer
cat > .puppeteer/config.json << 'EOF'
{
  "cacheDirectory": "/tmp/puppeteer_cache",
  "downloadPath": "/tmp/puppeteer_cache"
}
EOF

# Configurar variables de entorno
export PUPPETEER_CACHE_DIR="/tmp/puppeteer_cache"
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Crear directorio de cache
mkdir -p /tmp/puppeteer_cache

# Crear archivo de configuración para Node.js
cat > node-config.js << 'EOF'
// Configuración para Node.js 20
if (typeof globalThis.File === 'undefined') {
  globalThis.File = class File {
    constructor(chunks, filename, options = {}) {
      this.name = filename;
      this.size = 0;
      this.type = options.type || '';
      this.lastModified = Date.now();
    }
  };
}

if (typeof globalThis.Blob === 'undefined') {
  globalThis.Blob = class Blob {
    constructor(chunks = [], options = {}) {
      this.size = 0;
      this.type = options.type || '';
    }
  };
}
EOF

# Verificar instalación
echo "✅ Verificando instalación..."
npm list --depth=0

echo "🎯 Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Reiniciar el bot: ./pm2-manager.sh start"
echo "2. Verificar logs: ./pm2-manager.sh logs"
echo ""
echo "⚠️  Si el error persiste, recomiendo usar Node.js 18:"
echo "   bash fix-undici-error.sh"
