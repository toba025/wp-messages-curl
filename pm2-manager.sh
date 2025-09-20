#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
LOG_DIR="$PROJECT_DIR/logs"

# Verificar si estamos en el directorio correcto
if [ ! -f "server.js" ]; then
    echo -e "${RED}❌ Error: server.js no encontrado en el directorio actual${NC}"
    echo "Directorio actual: $(pwd)"
    echo "Archivos encontrados:"
    ls -la
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}🤖 Gestor de WhatsApp Bot con PM2${NC}"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  ${GREEN}start${NC}     - Iniciar el bot con PM2"
    echo "  ${GREEN}stop${NC}      - Detener el bot"
    echo "  ${GREEN}restart${NC}   - Reiniciar el bot"
    echo "  ${GREEN}status${NC}    - Ver estado del bot"
    echo "  ${GREEN}logs${NC}      - Ver logs en tiempo real"
    echo "  ${GREEN}monitor${NC}   - Abrir monitor de PM2"
    echo "  ${GREEN}setup${NC}     - Configurar PM2 para inicio automático"
    echo "  ${GREEN}clean${NC}     - Limpiar logs antiguos"
    echo "  ${GREEN}uninstall${NC} - Desinstalar PM2 y el bot"
    echo ""
}

check_pm2() {
    if ! command -v pm2 &> /dev/null; then
        echo -e "${RED}❌ PM2 no está instalado${NC}"
        echo "Instalando PM2..."
        npm install -g pm2
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ PM2 instalado correctamente${NC}"
        else
            echo -e "${RED}❌ Error instalando PM2${NC}"
            exit 1
        fi
    fi
}

check_display() {
    if ! pgrep -x "Xvfb" > /dev/null; then
        echo -e "${YELLOW}⚠️  Iniciando display virtual...${NC}"
        export DISPLAY=:99
        Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset > /dev/null 2>&1 &
        sleep 3
        echo -e "${GREEN}✅ Display virtual iniciado${NC}"
    else
        echo -e "${GREEN}✅ Display virtual ya está corriendo${NC}"
        export DISPLAY=:99
    fi
}

setup_logs() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        echo -e "${GREEN}✅ Directorio de logs creado${NC}"
    fi
}

start_bot() {
    echo -e "${BLUE}🚀 Iniciando WhatsApp Bot...${NC}"
    
    check_pm2
    check_display
    setup_logs
    
    cd "$PROJECT_DIR"
    
    if pm2 describe whatsapp-bot > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  El bot ya está corriendo${NC}"
        pm2 restart whatsapp-bot
    else
        pm2 start ecosystem.config.js
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Bot iniciado correctamente${NC}"
        echo ""
        echo -e "${BLUE}📋 Información útil:${NC}"
        echo "  - Ver estado: $0 status"
        echo "  - Ver logs: $0 logs"
        echo "  - Monitor: $0 monitor"
    else
        echo -e "${RED}❌ Error iniciando el bot${NC}"
        exit 1
    fi
}

stop_bot() {
    echo -e "${BLUE}🛑 Deteniendo WhatsApp Bot...${NC}"
    
    check_pm2
    
    if pm2 describe whatsapp-bot > /dev/null 2>&1; then
        pm2 stop whatsapp-bot
        pm2 delete whatsapp-bot
        echo -e "${GREEN}✅ Bot detenido correctamente${NC}"
    else
        echo -e "${YELLOW}⚠️  El bot no está corriendo${NC}"
    fi
}

restart_bot() {
    echo -e "${BLUE}🔄 Reiniciando WhatsApp Bot...${NC}"
    
    check_pm2
    check_display
    
    if pm2 describe whatsapp-bot > /dev/null 2>&1; then
        pm2 restart whatsapp-bot
        echo -e "${GREEN}✅ Bot reiniciado correctamente${NC}"
    else
        echo -e "${YELLOW}⚠️  El bot no está corriendo, iniciando...${NC}"
        start_bot
    fi
}

show_status() {
    echo -e "${BLUE}📊 Estado del WhatsApp Bot:${NC}"
    echo ""
    
    check_pm2
    
    if pm2 describe whatsapp-bot > /dev/null 2>&1; then
        pm2 show whatsapp-bot
    else
        echo -e "${RED}❌ El bot no está corriendo${NC}"
        echo "Usa '$0 start' para iniciarlo"
    fi
}

show_logs() {
    echo -e "${BLUE}📝 Logs del WhatsApp Bot:${NC}"
    echo "Presiona Ctrl+C para salir"
    echo ""
    
    check_pm2
    
    if pm2 describe whatsapp-bot > /dev/null 2>&1; then
        pm2 logs whatsapp-bot --lines 50
    else
        echo -e "${RED}❌ El bot no está corriendo${NC}"
        echo "Usa '$0 start' para iniciarlo"
    fi
}

open_monitor() {
    echo -e "${BLUE}📊 Abriendo monitor de PM2...${NC}"
    echo "Presiona 'q' para salir del monitor"
    echo ""
    
    check_pm2
    pm2 monit
}

setup_autostart() {
    echo -e "${BLUE}⚙️  Configurando inicio automático...${NC}"
    
    check_pm2
    
    pm2 startup
    
    echo -e "${YELLOW}⚠️  Ejecuta el comando que aparece arriba como root${NC}"
    echo ""
    
    if pm2 describe whatsapp-bot > /dev/null 2>&1; then
        pm2 save
        echo -e "${GREEN}✅ Configuración guardada${NC}"
    else
        echo -e "${YELLOW}⚠️  Inicia el bot primero con '$0 start' y luego ejecuta 'pm2 save'${NC}"
    fi
}

clean_logs() {
    echo -e "${BLUE}🧹 Limpiando logs antiguos...${NC}"
    
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "*.log" -mtime +7 -delete
        pm2 flush whatsapp-bot 2>/dev/null || true
        echo -e "${GREEN}✅ Logs limpiados${NC}"
    else
        echo -e "${YELLOW}⚠️  No hay directorio de logs${NC}"
    fi
}

uninstall() {
    echo -e "${RED}🗑️  Desinstalando WhatsApp Bot...${NC}"
    
    if pm2 describe whatsapp-bot > /dev/null 2>&1; then
        pm2 delete whatsapp-bot
    fi
    
    pm2 unstartup
    npm uninstall -g pm2
    
    echo -e "${GREEN}✅ Desinstalación completada${NC}"
}

main() {
    case "${1:-help}" in
        "start")
            start_bot
            ;;
        "stop")
            stop_bot
            ;;
        "restart")
            restart_bot
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "monitor")
            open_monitor
            ;;
        "setup")
            setup_autostart
            ;;
        "clean")
            clean_logs
            ;;
        "uninstall")
            uninstall
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

main "$@"
