#!/bin/bash

# Script específico para solucionar el error de undici con Node.js 20
# Este script soluciona el error "File is not defined" en undici

echo "🔧 Solucionando error de undici con Node.js 20..."

# Detener PM2
echo "🛑 Deteniendo PM2..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Verificar versión de Node.js
echo "📋 Versión de Node.js: $(node --version)"

# Opción 1: Downgrade a Node.js 18 (Recomendado)
echo "🎯 Opción 1: Instalando Node.js 18.x (Recomendado para venom-bot)..."

# Instalar Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar nueva versión
echo "✅ Nueva versión de Node.js: $(node --version)"

# Limpiar e reinstalar dependencias
echo "🧹 Limpiando dependencias..."
rm -rf node_modules package-lock.json
npm cache clean --force

# Crear .npmrc con configuración específica
cat > .npmrc << 'EOF'
legacy-peer-deps=true
fund=false
audit=false
EOF

# Reinstalar dependencias
echo "📦 Reinstalando dependencias..."
npm install

# Verificar instalación
echo "✅ Verificando instalación..."
npm list --depth=0

echo "🎯 Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Reiniciar el bot: ./pm2-manager.sh start"
echo "2. Verificar logs: ./pm2-manager.sh logs"
echo ""
echo "💡 Si prefieres mantener Node.js 20, ejecuta:"
echo "   bash fix-node20-compatibility.sh"
