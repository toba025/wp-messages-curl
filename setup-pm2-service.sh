#!/bin/bash


echo "⚙️  Configurando PM2 como servicio del sistema..."

if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script debe ejecutarse como root (sudo)"
    echo "Uso: sudo bash setup-pm2-service.sh"
    exit 1
fi

if ! command -v pm2 &> /dev/null; then
    echo "❌ PM2 no está instalado. Instalando..."
    npm install -g pm2
fi

if ! id "pm2" &>/dev/null; then
    echo "👤 Creando usuario pm2..."
    useradd -r -s /bin/false pm2
fi

mkdir -p /var/log/pm2
mkdir -p /etc/pm2
mkdir -p /home/ubuntu/.pm2

chown -R pm2:pm2 /var/log/pm2
chown -R ubuntu:ubuntu /home/ubuntu/.pm2

cat > /etc/systemd/system/pm2-ubuntu.service << 'EOF'
[Unit]
Description=PM2 process manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=forking
User=ubuntu
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Environment=PATH=/usr/bin:/usr/local/bin
Environment=PM2_HOME=/home/ubuntu/.pm2
ExecStart=/usr/local/bin/pm2 resurrect
ExecReload=/usr/local/bin/pm2 reload all
ExecStop=/usr/local/bin/pm2 kill
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/local/bin/pm2-init.sh << 'EOF'
#!/bin/bash

# Script de inicialización de PM2 para WhatsApp Bot
export DISPLAY=:99

# Iniciar display virtual si no está corriendo
if ! pgrep -x "Xvfb" > /dev/null; then
    Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
    sleep 3
fi

# Navegar al directorio del proyecto
cd /home/ubuntu/server-wp

# Iniciar el bot si no está corriendo
if ! pm2 describe whatsapp-bot > /dev/null 2>&1; then
    pm2 start ecosystem.config.js
    pm2 save
fi
EOF

chmod +x /usr/local/bin/pm2-init.sh

cat > /etc/systemd/system/whatsapp-bot-init.service << 'EOF'
[Unit]
Description=WhatsApp Bot Initialization
After=network.target pm2-ubuntu.service
Requires=pm2-ubuntu.service

[Service]
Type=oneshot
User=ubuntu
ExecStart=/usr/local/bin/pm2-init.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable pm2-ubuntu.service
systemctl enable whatsapp-bot-init.service

echo "✅ Servicios configurados correctamente"
echo ""
echo "📋 Servicios creados:"
echo "  - pm2-ubuntu.service (gestor de procesos PM2)"
echo "  - whatsapp-bot-init.service (inicialización del bot)"
echo ""
echo "🚀 Para iniciar los servicios:"
echo "  sudo systemctl start pm2-ubuntu"
echo "  sudo systemctl start whatsapp-bot-init"
echo ""
echo "📊 Para verificar el estado:"
echo "  sudo systemctl status pm2-ubuntu"
echo "  sudo systemctl status whatsapp-bot-init"
echo "  pm2 status"
echo ""
echo "🔄 Para reiniciar:"
echo "  sudo systemctl restart pm2-ubuntu"
echo ""
echo "⚠️  IMPORTANTE: Ejecuta 'pm2 save' después de iniciar el bot para guardar la configuración"
