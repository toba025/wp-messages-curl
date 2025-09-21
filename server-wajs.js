const fs = require('fs');
const { Client, LocalAuth } = require('whatsapp-web.js');
const express = require('express');
const bodyParser = require('body-parser');
const qrcode = require('qrcode-terminal');

const app = express();
app.use(bodyParser.json());

const TOKEN = 'E8t4t5yxuRgP9n3xWaBQbHfKJZCvLmNsTqVuXy2z45a7d9FgHiJkL0MnOpQrStUv';
const SESSION_NAME = 'session1';

// Variables globales para el cliente y estado
let client = null;
let isConnected = false;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 5;

// Función para logging con timestamp
function log(message, type = 'INFO') {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [${type}] ${message}`);
}

// Función para verificar el estado de conexión
async function checkConnectionStatus() {
  if (!client) {
    return false;
  }

  try {
    const state = await client.getState();
    return state === 'CONNECTED';
  } catch (error) {
    log(`Error verificando estado de conexión: ${error.message}`, 'ERROR');
    return false;
  }
}

// Función para inicializar whatsapp-web.js
async function initializeWhatsApp() {
  try {
    log('🚀 Inicializando WhatsApp Web...');
    
    client = new Client({
      authStrategy: new LocalAuth({
        clientId: SESSION_NAME
      }),
      puppeteer: {
        headless: true,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-accelerated-2d-canvas',
          '--no-first-run',
          '--no-zygote',
          '--single-process',
          '--disable-gpu',
          '--disable-web-security',
          '--disable-features=VizDisplayCompositor',
          '--disable-extensions',
          '--disable-plugins',
          '--disable-images',
          '--disable-javascript-harmony-shipping',
          '--disable-background-timer-throttling',
          '--disable-backgrounding-occluded-windows',
          '--disable-renderer-backgrounding',
          '--disable-features=TranslateUI',
          '--disable-ipc-flooding-protection',
          '--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        ]
      }
    });

    // Eventos del cliente
    client.on('qr', (qr) => {
      log('📱 Código QR generado. Escanea con WhatsApp:', 'INFO');
      qrcode.generate(qr, { small: true });
    });

    client.on('ready', () => {
      log('✅ WhatsApp Web conectado exitosamente', 'INFO');
      isConnected = true;
      reconnectAttempts = 0;
    });

    client.on('authenticated', () => {
      log('🔐 WhatsApp Web autenticado', 'INFO');
    });

    client.on('auth_failure', (msg) => {
      log(`❌ Error de autenticación: ${msg}`, 'ERROR');
      isConnected = false;
    });

    client.on('disconnected', (reason) => {
      log(`❌ WhatsApp Web desconectado: ${reason}`, 'ERROR');
      isConnected = false;
    });

    // Inicializar el cliente
    await client.initialize();
    
    log('✅ Cliente WhatsApp Web inicializado correctamente');
    return true;

  } catch (error) {
    log(`❌ Error inicializando WhatsApp Web: ${error.message}`, 'ERROR');
    isConnected = false;
    return false;
  }
}

// Función para reconectar
async function reconnect() {
  if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
    log('❌ Máximo número de intentos de reconexión alcanzado', 'ERROR');
    return false;
  }

  reconnectAttempts++;
  log(`🔄 Intento de reconexión ${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS}`);
  
  // Esperar antes de reconectar
  await new Promise(resolve => setTimeout(resolve, 5000 * reconnectAttempts));
  
  return await initializeWhatsApp();
}

// Función para enviar mensaje con validaciones
async function sendMessage(number, message) {
  try {
    // Verificar si el cliente está disponible
    if (!client) {
      throw new Error('Cliente WhatsApp no está disponible');
    }

    // Verificar estado de conexión
    const connectionStatus = await checkConnectionStatus();
    if (!connectionStatus) {
      log('⚠️  Cliente no conectado, intentando reconectar...', 'WARN');
      const reconnected = await reconnect();
      if (!reconnected) {
        throw new Error('No se pudo reconectar al WhatsApp');
      }
    }

    // Validar número de teléfono
    const cleanNumber = number.replace(/\D/g, ''); // Remover caracteres no numéricos
    if (cleanNumber.length < 10) {
      throw new Error('Número de teléfono inválido');
    }

    // Formatear número para WhatsApp Web
    const formattedNumber = cleanNumber.includes('@c.us') ? cleanNumber : `${cleanNumber}@c.us`;
    
    log(`📤 Enviando mensaje a ${formattedNumber}`);
    
    // Enviar mensaje
    const result = await client.sendMessage(formattedNumber, message);
    
    log(`✅ Mensaje enviado exitosamente a ${formattedNumber}`);
    return result;

  } catch (error) {
    log(`❌ Error enviando mensaje: ${error.message}`, 'ERROR');
    throw error;
  }
}

// Inicializar el servidor
async function startServer() {
  // Inicializar WhatsApp Web
  const whatsappInitialized = await initializeWhatsApp();
  
  if (!whatsappInitialized) {
    log('❌ No se pudo inicializar WhatsApp Web. El servidor se iniciará sin WhatsApp.', 'ERROR');
  }

  // Configurar rutas
  app.post('/send-message', async (req, res) => {
    try {
      const { token, number, message } = req.body;
      
      // Validar token
      if (token !== TOKEN) {
        return res.status(401).json({ error: 'Token inválido' });
      }
      
      // Validar parámetros
      if (!number || !message) {
        return res.status(400).json({ error: 'Faltan parámetros: number y message son requeridos' });
      }

      // Enviar mensaje
      const result = await sendMessage(number, message);
      res.json({ 
        status: 'success', 
        message: 'Mensaje enviado exitosamente',
        result: result 
      });

    } catch (error) {
      log(`❌ Error en endpoint /send-message: ${error.message}`, 'ERROR');
      res.status(500).json({ 
        error: 'Error enviando mensaje', 
        details: error.message 
      });
    }
  });

  // Endpoint para verificar estado
  app.get('/status', async (req, res) => {
    try {
      const connectionStatus = await checkConnectionStatus();
      res.json({
        status: 'ok',
        whatsapp_connected: connectionStatus,
        server_time: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        status: 'error',
        whatsapp_connected: false,
        error: error.message
      });
    }
  });

  // Iniciar servidor
  app.listen(8002, () => {
    log('🌐 Servidor API REST iniciado en puerto 8002');
    log('📋 Endpoints disponibles:');
    log('  POST /send-message - Enviar mensaje de WhatsApp');
    log('  GET /status - Verificar estado del servidor');
  });
}

// Manejar cierre graceful
process.on('SIGINT', () => {
  log('🛑 Cerrando servidor...');
  if (client) {
    client.destroy();
  }
  process.exit(0);
});

// Iniciar el servidor
startServer().catch(error => {
  log(`❌ Error fatal: ${error.message}`, 'ERROR');
  process.exit(1);
});
