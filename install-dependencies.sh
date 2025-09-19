#!/bin/bash

# Script de instalación de dependencias para WhatsApp Bot en Ubuntu
# Ejecutar con: sudo bash install-dependencies.sh

echo "🚀 Instalando dependencias para WhatsApp Bot..."

# Actualizar sistema
echo "📦 Actualizando sistema..."
apt update && apt upgrade -y

# Instalar dependencias del sistema
echo "🔧 Instalando dependencias del sistema..."
apt install -y \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    curl \
    unzip \
    xvfb \
    x11vnc \
    fluxbox

# Instalar Google Chrome
echo "🌐 Instalando Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt update
apt install -y google-chrome-stable

# Verificar instalación de Chrome
if [ -f "/usr/bin/google-chrome-stable" ]; then
    echo "✅ Google Chrome instalado correctamente"
else
    echo "⚠️  Chrome no se instaló correctamente, intentando con Chromium..."
    apt install -y chromium-browser
fi

# Instalar Node.js 20.x si no está instalado
if ! command -v node &> /dev/null; then
    echo "📱 Instalando Node.js 20.x..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
else
    echo "✅ Node.js ya está instalado: $(node --version)"
fi

# Verificar versiones
echo "📋 Verificando instalaciones:"
echo "Node.js: $(node --version)"
echo "NPM: $(npm --version)"
if [ -f "/usr/bin/google-chrome-stable" ]; then
    echo "Chrome: $(google-chrome-stable --version)"
elif [ -f "/usr/bin/chromium-browser" ]; then
    echo "Chromium: $(chromium-browser --version)"
fi

# Crear directorio para sesiones de WhatsApp
echo "📁 Creando directorio para sesiones..."
mkdir -p /home/ubuntu/whatsapp-sessions
chown ubuntu:ubuntu /home/ubuntu/whatsapp-sessions

# Configurar variables de entorno
echo "🔧 Configurando variables de entorno..."
cat >> /home/ubuntu/.bashrc << 'EOF'

# WhatsApp Bot Environment Variables
export DISPLAY=:99
export CHROME_BIN=/usr/bin/google-chrome-stable
EOF

# Crear servicio systemd para el bot
echo "⚙️  Creando servicio systemd..."
cat > /etc/systemd/system/whatsapp-bot.service << 'EOF'
[Unit]
Description=WhatsApp Bot Service
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/server-wp
Environment=NODE_ENV=production
Environment=DISPLAY=:99
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=whatsapp-bot

[Install]
WantedBy=multi-user.target
EOF

# Crear script de inicio con display virtual
echo "🖥️  Creando script de inicio con display virtual..."
cat > /home/ubuntu/start-bot.sh << 'EOF'
#!/bin/bash

# Iniciar display virtual
echo "🖥️  Iniciando display virtual..."
Xvfb :99 -screen 0 1024x768x24 &
export DISPLAY=:99

# Esperar un momento para que el display se inicialice
sleep 3

# Iniciar el bot
echo "🚀 Iniciando WhatsApp Bot..."
cd /home/ubuntu/server-wp
node server.js
EOF

chmod +x /home/ubuntu/start-bot.sh
chown ubuntu:ubuntu /home/ubuntu/start-bot.sh

# Instalar PM2 globalmente para gestión de procesos
echo "📦 Instalando PM2 para gestión de procesos..."
npm install -g pm2

# Crear archivo de configuración PM2
cat > /home/ubuntu/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'whatsapp-bot',
    script: 'server.js',
    cwd: '/home/ubuntu/server-wp',
    env: {
      NODE_ENV: 'production',
      DISPLAY: ':99'
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

chown ubuntu:ubuntu /home/ubuntu/ecosystem.config.js

# Crear directorio de logs
mkdir -p /home/ubuntu/server-wp/logs
chown ubuntu:ubuntu /home/ubuntu/server-wp/logs

echo "✅ Instalación completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Reinicia el servidor: sudo reboot"
echo "2. Navega al directorio del proyecto: cd /home/ubuntu/server-wp"
echo "3. Instala las dependencias de Node.js: npm install"
echo "4. Inicia el bot con PM2: pm2 start ecosystem.config.js"
echo "5. Verifica el estado: pm2 status"
echo "6. Ver logs: pm2 logs whatsapp-bot"
echo ""
echo "🔧 Comandos útiles:"
echo "  - Reiniciar bot: pm2 restart whatsapp-bot"
echo "  - Detener bot: pm2 stop whatsapp-bot"
echo "  - Ver estado: pm2 status"
echo "  - Ver logs en tiempo real: pm2 logs whatsapp-bot --lines 50"
